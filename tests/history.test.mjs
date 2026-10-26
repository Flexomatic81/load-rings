// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  VALID_MINUTES,
  HISTORY_MS,
  MAX_SAMPLES,
  validMinutes,
  createHistory,
  pushSample,
  selectGpu,
  windowOf,
  graphPaths,
} from "../package/contents/code/history.mjs";

const s = (timestamp, extra = {}) => ({
  timestamp,
  intervalMs: 2000,
  cpu: 10,
  ram: 20,
  gpu: null,
  gpuId: null,
  cpuTemp: null,
  gpuTemp: null,
  ...extra,
});
const run = (samples) => samples.reduce((h, x) => pushSample(h, x), createHistory());

test("constants", () => {
  assert.deepEqual(VALID_MINUTES, [1, 5, 15, 60]);
  assert.equal(HISTORY_MS, 3_600_000);
  assert.equal(MAX_SAMPLES, 7201);
});

test("a new history is empty", () => {
  assert.deepEqual(createHistory(), {
    times: [],
    intervals: [],
    cpu: [],
    ram: [],
    gpu: [],
    gpuId: null,
    peakCpuTemp: null,
    peakGpuTemp: null,
  });
});

test("pushSample is pure and stores every series", () => {
  const empty = createHistory();
  const h = pushSample(empty, s(1000, { cpu: 33, ram: 44, gpu: 55, gpuId: "g", intervalMs: 500 }));
  assert.equal(empty.times.length, 0);
  assert.deepEqual(h.times, [1000]);
  assert.deepEqual(h.intervals, [500]);
  assert.deepEqual([h.cpu, h.ram, h.gpu], [[33], [44], [55]]);
});

test("peaks ignore missing values and survive eviction", () => {
  const h = run([s(0, { cpuTemp: 70 }), s(2000, { cpuTemp: null }), s(3_700_000, { cpuTemp: 55 })]);
  assert.equal(h.peakCpuTemp, 70);
  assert.equal(h.cpu.length, 1);
});

test("the peak follows the maximum, for both temperatures", () => {
  const h = run([
    s(0, { cpuTemp: 50, gpuTemp: 60, gpuId: "g" }),
    s(2000, { cpuTemp: 80, gpuTemp: 40, gpuId: "g" }),
    s(4000, { cpuTemp: 60, gpuTemp: 65, gpuId: "g" }),
  ]);
  assert.equal(h.peakCpuTemp, 80);
  assert.equal(h.peakGpuTemp, 65);
});

test("points older than an hour fall out", () => {
  const samples = [];
  for (let t = 0; t <= 3_602_000; t += 2000) samples.push(s(t));
  const h = run(samples);
  assert.equal(h.times[0], 2000);
  assert.equal(h.times.at(-1), 3_602_000);
});

test("the sample count is capped", () => {
  const samples = Array.from({ length: MAX_SAMPLES + 50 }, (_, i) => s(i * 100, { intervalMs: 100 }));
  const h = run(samples);
  assert.equal(h.times.length, MAX_SAMPLES);
  assert.equal(h.times.at(-1), (MAX_SAMPLES + 49) * 100);
});

test("a pause becomes a gap", () => {
  const h = run([0, 2000, 4000, 60000, 62000].map((t) => s(t)));
  assert.deepEqual(windowOf(h, 5, 62000).cpu, [10, 10, 10, null, 10, 10]);
});

test("the gap point lies between its neighbours", () => {
  const w = windowOf(run([s(0), s(60000)]), 5, 60000);
  assert.equal(w.times.length, 3);
  assert.ok(w.times[1] > 0 && w.times[1] < 60000);
  assert.deepEqual(w.ram, [20, null, 20]);
  assert.deepEqual(w.gpu, [null, null, null]);
});

test("switching from 0.5 s to 10 s keeps the hour and adds no gap", () => {
  const fast = Array.from({ length: 7200 }, (_, i) => s(i * 500, { intervalMs: 500 }));
  const slow = Array.from({ length: 10 }, (_, i) => s(3_600_000 + i * 10000, { intervalMs: 10000 }));
  const w = windowOf(run([...fast, ...slow]), 60, 3_690_000);
  assert.ok(w.times[0] <= 90_000);
  assert.ok(!w.cpu.includes(null));
});

test("switching from 10 s to 0.5 s adds no gap", () => {
  const slow = Array.from({ length: 10 }, (_, i) => s(i * 10000, { intervalMs: 10000 }));
  const fast = Array.from({ length: 10 }, (_, i) => s(100_000 + i * 500, { intervalMs: 500 }));
  assert.ok(!windowOf(run([...slow, ...fast]), 5, 104_500).cpu.includes(null));
});

test("the window drops older points", () => {
  const h = run(Array.from({ length: 121 }, (_, i) => s(i * 1000, { cpu: i })));
  const w = windowOf(h, 1, 120_000);
  assert.equal(w.times[0], 60_000);
  assert.equal(w.times.length, 61);
  assert.equal(w.cpu[0], 60);
});

test("an empty history gives an empty window", () => {
  assert.deepEqual(windowOf(createHistory(), 5, 1000), { times: [], cpu: [], ram: [], gpu: [] });
});

test("another gpu clears the gpu history and its peak", () => {
  const h = run([s(0, { gpu: 80, gpuId: "gpu0", gpuTemp: 90 }), s(2000, { gpu: 10, gpuId: "gpu1", gpuTemp: 50 })]);
  assert.deepEqual(h.gpu, [null, 10]);
  assert.equal(h.peakGpuTemp, 50);
  assert.equal(h.gpuId, "gpu1");
});

test("selecting another gpu clears at once, without a new sample", () => {
  const before = run([s(0, { gpu: 80, gpuId: "gpu0", gpuTemp: 90 })]);
  const h = selectGpu(before, "gpu1");
  assert.deepEqual(h.gpu, [null]);
  assert.equal(h.peakGpuTemp, null);
  assert.equal(h.gpuId, "gpu1");
  assert.deepEqual(before.gpu, [80]);
  const same = run([s(0, { gpuId: "gpu0" })]);
  assert.equal(selectGpu(same, "gpu0"), same);
});

test("turning the gpu off clears it too", () => {
  const h = run([s(0, { gpu: 80, gpuId: "gpu0", gpuTemp: 90 }), s(2000, { gpu: null, gpuId: null })]);
  assert.deepEqual(h.gpu, [null, null]);
  assert.equal(h.peakGpuTemp, null);
  assert.equal(h.gpuId, null);
});

test("selectGpu treats undefined as no gpu", () => {
  const h = createHistory();
  assert.equal(selectGpu(h, undefined), h);
});

test("selectGpu treats an empty id as no gpu", () => {
  const h = createHistory();
  assert.equal(selectGpu(h, ""), h);
  const other = selectGpu(h, "gpu0");
  assert.equal(selectGpu(other, "").gpuId, null);
});

test("valid minutes", () => {
  assert.equal(validMinutes(15), 15);
  assert.equal(validMinutes(7), 5);
  assert.equal(validMinutes(undefined), 5);
});

test("graphPaths: one section per run of values", () => {
  const p = graphPaths([0, 30000, 60000], [0, 100, 50], { minutes: 1, now: 60000, width: 100, height: 50 });
  assert.equal(p.line, "M 0 50 L 50 0 L 100 25");
  assert.equal(p.fill, "M 0 50 L 50 0 L 100 25 L 100 50 L 0 50 Z");
});

test("graphPaths: a null splits the sections", () => {
  const p = graphPaths([0, 10000, 20000, 30000, 40000], [100, 100, null, 0, 0], {
    minutes: 1,
    now: 60000,
    width: 60,
    height: 10,
  });
  assert.equal(p.line, "M 0 0 L 10 0 M 30 10 L 40 10");
  assert.equal(p.fill.split("Z").length - 1, 2);
});

test("graphPaths: points outside the window are skipped, a lone point is a dot, nothing gives empty paths", () => {
  assert.deepEqual(graphPaths([], [], { minutes: 1, now: 1000, width: 100, height: 50 }), { line: "", fill: "" });
  assert.deepEqual(graphPaths([0], [10], { minutes: 1, now: 1_000_000, width: 100, height: 50 }), {
    line: "",
    fill: "",
  });
  const dot = graphPaths([60000], [0], { minutes: 1, now: 60000, width: 100, height: 50 });
  assert.equal(dot.line, "M 100 50 L 100 50");
  assert.equal(dot.fill, "");
  const clamped = graphPaths([60000], [150], { minutes: 1, now: 60000, width: 100, height: 50 });
  assert.equal(clamped.line, "M 100 0 L 100 0");
});
