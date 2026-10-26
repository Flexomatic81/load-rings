// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The screenshot tool: its demo data stays generic and matches what the views read, and the image check reads PNG
// files and finds missing images, path metadata and a graph or bar of one color.

import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import zlib from "node:zlib";
import {
  COLOR_STEPS,
  DEMO_CONTEXT_SWITCHES,
  DEMO_CPU,
  DEMO_FONTS,
  DEMO_GPU,
  DEMO_GPU_ID,
  SHOTS,
  colorRings,
  demoApps,
  demoCurrent,
  demoGpuOptions,
  demoHardware,
  demoHistory,
  demoRings,
  demoStats,
  pickFont,
} from "../tools/screenshots/demo.mjs";
import {
  checkImages,
  chartProblem,
  metadataProblems,
  main,
  parseArea,
  parseChartLine,
  readPng,
} from "../tools/screenshots/check-images.mjs";
import { topConsumers } from "../package/contents/code/apps.mjs";
import { ringColor } from "../package/contents/code/color.mjs";
import { memorySummary } from "../package/contents/code/hardware.mjs";
import { windowOf } from "../package/contents/code/history.mjs";
import { memoryBreakdown } from "../package/contents/code/memory.mjs";
import { ringValues } from "../package/contents/code/sensors.mjs";
import { substitute } from "../package/contents/code/text.mjs";

const GIB = 1024 ** 3;
const END = Date.UTC(2026, 9, 26, 12, 0, 0);
const t = { tr: (text, ...args) => substitute(text, args) };

// Every string inside a value, also in nested arrays and objects.
function strings(value, found = []) {
  if (typeof value === "string") found.push(value);
  else if (value !== null && typeof value === "object") Object.values(value).forEach((v) => strings(v, found));
  return found;
}

test("the demo hardware is the fixed sample machine", () => {
  assert.equal(DEMO_CPU, "AMD Ryzen 7 5800X3D");
  assert.equal(DEMO_GPU, "AMD Radeon RX 6900 XT");
  const hardware = demoHardware();
  assert.equal(hardware.cpuModel, DEMO_CPU);
  assert.equal(hardware.physicalCores, 8);
  assert.equal(demoCurrent().coreCount, 16);
  assert.equal(demoCurrent().cores.length, 16);
  assert.deepEqual(memorySummary(hardware.memory, demoCurrent().memTotal, t), ["DDR4-3200", "4 × 8 GiB"]);
  assert.equal(demoCurrent().gpu.name, DEMO_GPU);
  assert.deepEqual(demoGpuOptions(), [{ text: DEMO_GPU, value: DEMO_GPU_ID }]);
});

test("the demo data names no person, path or machine", () => {
  const all = strings([demoCurrent(), demoStats(), demoHardware(), demoApps(), demoGpuOptions()]);
  assert.ok(!all.some((s) => s.includes("/")), "no paths");
  assert.equal(demoHardware().memory.manufacturer, null, "no memory maker");
  assert.doesNotMatch(all.join(" "), /serial|@|\.local|home/i);
});

test("the snapshot has every value the popup reads, and the numbers agree", () => {
  const current = demoCurrent();
  for (const key of ["cpuUsage", "cpuFrequency", "cpuMaxFrequency", "cpuTemperature", "memUsed", "memApplication"]) {
    assert.ok(Number.isFinite(current[key]), key);
  }
  const mean = current.cores.reduce((sum, core) => sum + core.usage, 0) / current.cores.length;
  assert.equal(mean, current.cpuUsage, "the cores average to the ring");
  assert.ok(Math.abs(current.memUsedPercent - (current.memUsed / current.memTotal) * 100) < 1e-9);
  assert.ok(current.cpuFrequency <= current.cpuMaxFrequency);
  for (const value of Object.values(current.gpu)) assert.ok(typeof value === "string" || Number.isFinite(value));
  assert.ok(current.gpu.usedVram < current.gpu.totalVram);
  // The memory bar: programs, system, cache and free add up to the total.
  const segments = memoryBreakdown({
    total: current.memTotal,
    used: current.memUsed,
    application: current.memApplication,
    memFree: demoStats().memFree,
  });
  assert.equal(segments.length, 4);
  assert.ok(segments.every((s) => s.bytes > 0));
  assert.ok(Math.abs(segments.reduce((sum, s) => sum + s.bytes, 0) - current.memTotal) < 1);
  assert.ok(current.swapUsed < current.swapTotal);
  assert.equal(DEMO_CONTEXT_SWITCHES > 0, true);
});

test("the history covers fifteen minutes and ends at the values of the snapshot", () => {
  const history = demoHistory(END);
  const current = demoCurrent();
  const last = history.times.length - 1;
  assert.equal(history.times.length, 450);
  assert.equal(history.times[last], END);
  assert.equal(history.times[last] - history.times[0], 449 * 2000);
  assert.equal(history.gpuId, DEMO_GPU_ID);
  assert.equal(history.cpu[last], current.cpuUsage);
  assert.equal(history.ram[last], current.memUsedPercent);
  assert.equal(history.gpu[last], current.gpu.usage);
  assert.ok(history.peakCpuTemp > current.cpuTemperature);
  assert.ok(history.peakGpuTemp > current.gpu.temperature);
  // The five minutes the popup shows have no gap and a load peak well above the current load.
  const shown = windowOf(history, 5, END);
  assert.equal(shown.times.length, 151);
  assert.ok(shown.cpu.every((v) => v !== null));
  assert.ok(Math.max(...shown.cpu) > current.cpuUsage + 20);
  assert.deepEqual(demoHistory(END), history, "the data is the same on every run");
});

test("the programs rank as in the popup, with the background services among them", () => {
  const apps = demoApps();
  const cpu = topConsumers(apps, "cpu", 100);
  const memory = topConsumers(apps, "memory", demoCurrent().memTotal);
  assert.equal(cpu.length, 5);
  assert.equal(cpu[0].name, "Kdenlive");
  assert.equal(memory[0].name, "Falkon");
  assert.ok(cpu.some((row) => row.kind === "service"));
  assert.ok(memory.some((row) => row.kind === "service"));
  const cpuSum = apps.reduce((sum, row) => sum + row.cpu, 0);
  assert.ok(cpuSum < demoCurrent().cpuUsage, "the programs use less than the whole processor");
  const memorySum = apps.reduce((sum, row) => sum + row.memory, 0);
  assert.ok(memorySum < demoCurrent().memApplication + GIB, "about the memory of the programs");
});

test("the rings: two by default, three with the card, and the color steps from green to red", () => {
  const current = demoCurrent();
  assert.deepEqual(demoRings(false), ringValues(current, false));
  assert.deepEqual(demoRings(true), ringValues(current, true));
  assert.deepEqual(
    colorRings().map((ring) => ring.percent),
    COLOR_STEPS,
  );
  // Increasing loads from the green to the red end of the scale, each ring in another color.
  assert.ok(COLOR_STEPS.every((p, i) => i === 0 || p > COLOR_STEPS[i - 1]));
  assert.ok(COLOR_STEPS[0] < 10 && COLOR_STEPS[COLOR_STEPS.length - 1] > 95);
  assert.equal(new Set(COLOR_STEPS.map(ringColor)).size, COLOR_STEPS.length);
});

test("the font is the first available of the fixed list", () => {
  assert.deepEqual(DEMO_FONTS, ["Noto Sans", "DejaVu Sans"]);
  assert.equal(pickFont(["DejaVu Sans", "Noto Sans", "Other"]), "Noto Sans");
  assert.equal(pickFont(["Other", "DejaVu Sans"]), "DejaVu Sans");
  assert.equal(pickFont(["Other"]), "");
});

test("the shots have fixed file names", () => {
  assert.deepEqual(SHOTS, [
    "panel.png",
    "panel-gpu.png",
    "panel-vertical.png",
    "panel-colors.png",
    "popup.png",
    "popup-gpu.png",
    "settings.png",
  ]);
});

// --- the image check ----------------------------------------------------------

function chunk(type, data) {
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0);
  out.write(type, 4, "latin1");
  data.copy(out, 8);
  out.writeUInt32BE(zlib.crc32(out.subarray(4, 8 + data.length)), 8 + data.length);
  return out;
}

// A PNG of `rows` (arrays of [r, g, b, a]), each row with the given filter type.
function makePng(rows, { filters = [], extra = [], colorType = 6 } = {}) {
  const width = rows[0].length;
  const channels = colorType === 6 ? 4 : 3;
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(rows.length, 4);
  header[8] = 8;
  header[9] = colorType;
  const raw = [];
  let previous = Buffer.alloc(width * channels);
  rows.forEach((row, y) => {
    const line = Buffer.from(row.flatMap((p) => p.slice(0, channels)));
    const filter = filters[y] ?? 0;
    raw.push(filter, ...encodeLine(filter, line, previous, channels));
    previous = line;
  });
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", header),
    ...extra,
    chunk("IDAT", zlib.deflateSync(Buffer.from(raw))),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}

function paeth(a, b, c) {
  const p = a + b - c;
  const pa = Math.abs(p - a);
  const pb = Math.abs(p - b);
  const pc = Math.abs(p - c);
  return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
}

function encodeLine(filter, line, previous, bpp) {
  return [...line].map((value, i) => {
    const a = i >= bpp ? line[i - bpp] : 0;
    const b = previous[i];
    const c = i >= bpp ? previous[i - bpp] : 0;
    const predictor = [0, a, b, Math.floor((a + b) / 2), paeth(a, b, c)][filter];
    return (value - predictor + 256) % 256;
  });
}

const RED = [255, 0, 0, 255];
const BLUE = [0, 0, 255, 255];

test("readPng decodes every filter type", () => {
  const rows = [
    [RED, BLUE, RED],
    [BLUE, RED, BLUE],
    [RED, RED, BLUE],
    [BLUE, BLUE, RED],
    [RED, BLUE, BLUE],
  ];
  const png = readPng(makePng(rows, { filters: [0, 1, 2, 3, 4] }));
  assert.equal(png.width, 3);
  assert.equal(png.height, 5);
  assert.deepEqual([...png.pixel(1, 0)], BLUE);
  assert.deepEqual([...png.pixel(2, 4)], BLUE);
  assert.deepEqual([...png.pixel(0, 3)], BLUE);
  const rgb = readPng(makePng(rows, { colorType: 2, filters: [4, 3, 2, 1, 0] }));
  assert.deepEqual([...rgb.pixel(1, 1)], RED);
});

test("readPng refuses what is not an 8-bit PNG", () => {
  assert.throws(() => readPng(Buffer.from("not a png")), /not a PNG/);
  const png = makePng([[RED]]);
  png[24] = 16; // bit depth
  assert.throws(() => readPng(png), /unsupported/);
});

test("metadata with a path or a time stamp is reported", () => {
  const plain = readPng(makePng([[RED]]));
  assert.deepEqual(metadataProblems(plain), []);
  const text = chunk("tEXt", Buffer.from("Source\0/somewhere/file.qml", "latin1"));
  const time = chunk("tIME", Buffer.alloc(7));
  const tagged = readPng(makePng([[RED]], { extra: [text, time] }));
  assert.deepEqual(metadataProblems(tagged), ["metadata chunk tEXt", "metadata chunk tIME"]);
});

test("a graph area of one color is reported, one with lines is not", () => {
  const flat = Array.from({ length: 10 }, () => Array.from({ length: 10 }, () => RED));
  const drawn = flat.map((row, y) => row.map((p, x) => (x === y ? BLUE : p)));
  const area = { x: 0, y: 0, width: 10, height: 10, sceneWidth: 10, sceneHeight: 10 };
  assert.match(chartProblem(readPng(makePng(flat)), area), /one color/);
  assert.equal(chartProblem(readPng(makePng(drawn)), area), "");
  // The area is given in scene units; a grab at twice the size scales it.
  assert.equal(chartProblem(readPng(makePng(drawn)), { ...area, width: 5, height: 5, sceneWidth: 5 }), "");
  assert.match(chartProblem(readPng(makePng(drawn)), { ...area, width: 0 }), /empty/);
});

test("the chart line of the scene is parsed", () => {
  assert.deepEqual(parseChartLine("qml: SCREENSHOT chart popup.png 10 20.5 300 140 of 528 720"), {
    x: 10,
    y: 20.5,
    width: 300,
    height: 140,
    sceneWidth: 528,
    sceneHeight: 720,
  });
  assert.equal(parseChartLine("qml: something else"), null);
  assert.deepEqual(parseArea("qml: SCREENSHOT bar popup.png 8 500 380 6 of 396 692", "bar"), {
    x: 8,
    y: 500,
    width: 380,
    height: 6,
    sceneWidth: 396,
    sceneHeight: 692,
  });
  assert.equal(parseArea("qml: SCREENSHOT chart popup.png 8 500 380 6 of 396 692", "bar"), null);
});

test("checkImages reports missing files and areas of one color", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "shots-"));
  try {
    const area = { x: 0, y: 0, width: 4, height: 4, sceneWidth: 4, sceneHeight: 4 };
    assert.deepEqual(
      checkImages(dir, { chart: area, bar: area }).problems,
      SHOTS.map((n) => `${n}: missing`),
    );
    const flat = Array.from({ length: 4 }, () => Array.from({ length: 4 }, () => RED));
    const drawn = flat.map((row, y) => row.map((p, x) => (x === y ? BLUE : p)));
    for (const name of SHOTS) fs.writeFileSync(path.join(dir, name), makePng(drawn));
    assert.deepEqual(checkImages(dir, { chart: area, bar: area }).problems, []);
    fs.writeFileSync(path.join(dir, "popup.png"), makePng(flat));
    const problems = checkImages(dir, { chart: area, bar: area }).problems.join("\n");
    assert.match(problems, /popup\.png: the graph area is one color/);
    assert.match(problems, /popup\.png: the memory bar area is one color/);
  } finally {
    fs.rmSync(dir, { recursive: true });
  }
});

test("main needs the graph and the bar line of the scene", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "shots-"));
  const log = path.join(dir, "scene.log");
  const quiet = { error: console.error, log: console.log };
  console.error = () => {};
  console.log = () => {};
  try {
    const flat = Array.from({ length: 4 }, () => Array.from({ length: 4 }, () => RED));
    const drawn = flat.map((row, y) => row.map((p, x) => (x === y ? BLUE : p)));
    for (const name of SHOTS) fs.writeFileSync(path.join(dir, name), makePng(drawn));
    fs.writeFileSync(log, "qml: SCREENSHOT bar popup.png 0 0 4 4 of 4 4\n");
    assert.equal(main([dir, "--log", log]), 1, "no graph line");
    fs.writeFileSync(log, "qml: SCREENSHOT chart popup.png 0 0 4 4 of 4 4\n");
    assert.equal(main([dir, "--log", log]), 1, "no bar line");
    fs.writeFileSync(
      log,
      "qml: SCREENSHOT chart popup.png 0 0 4 4 of 4 4\nqml: SCREENSHOT bar popup.png 0 0 4 4 of 4 4\n",
    );
    assert.equal(main([dir, "--log", log]), 0);
    fs.writeFileSync(path.join(dir, "popup.png"), makePng(flat));
    assert.equal(main([dir, "--log", log]), 1, "a popup of one color");
    assert.equal(main([dir, "--offscreen", log]), 2);
    assert.equal(main([dir, "--log"]), 2);
  } finally {
    console.error = quiet.error;
    console.log = quiet.log;
    fs.rmSync(dir, { recursive: true });
  }
});
