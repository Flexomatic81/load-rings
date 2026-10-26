// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { HARDWARE_COMMAND, parseHardware, memorySummary } from "../package/contents/code/hardware.mjs";
import { substitute } from "../package/contents/code/text.mjs";

const GiB = 2 ** 30;
const read = (name) => fs.readFileSync(new URL(`./fixtures/${name}`, import.meta.url), "utf8");
const t = (text, ...args) => substitute(text, args);
const dmi = (lines) => `@@dmi\n${lines.join("\n")}\n`;
const dimm = (i, size, extra = []) => [`MEMORY_DEVICE_${i}_SIZE=${size}`, ...extra];

test("desktop", () => {
  const hw = parseHardware(read("hardware-desktop.txt"));
  assert.equal(hw.cpuModel, "AMD Ryzen 7 5800X3D");
  assert.equal(hw.physicalCores, 8);
  assert.equal(hw.memory.modules.length, 4);
  assert.equal(hw.memory.speedMts, 3200);
  assert.deepEqual(memorySummary(hw.memory, 32 * GiB, t, ","), ["DDR4-3200", "4 × 8 GiB", "A-DATA"]);
});

test("laptop: hyperthreads share a core, (R)/(TM) are dropped, unknown manufacturer is left out", () => {
  const hw = parseHardware(read("hardware-laptop.txt"));
  assert.equal(hw.cpuModel, "13th Gen Intel Core i7-1355U");
  assert.equal(hw.physicalCores, 9);
  assert.deepEqual(memorySummary(hw.memory, 16 * GiB, t, ","), ["LPDDR5-6400", "16 GiB"]);
});

test("no dmi data shows only the total", () => {
  const hw = parseHardware(read("hardware-vm.txt"));
  assert.equal(hw.cpuModel, "QEMU Virtual CPU version 2.5+");
  assert.equal(hw.physicalCores, 2);
  assert.equal(hw.memory, null);
  assert.deepEqual(memorySummary(hw.memory, 8 * GiB, t, ","), ["8,0 GiB"]);
  assert.deepEqual(memorySummary(undefined, 512 * 2 ** 20, t), ["512 MiB"]);
});

test("mixed sizes", () => {
  const hw = parseHardware(dmi([...dimm(0, 8 * GiB), ...dimm(1, 16 * GiB)]));
  assert.deepEqual(memorySummary(hw.memory, 24 * GiB, t), ["8 GiB + 16 GiB"]);
  const three = parseHardware(dmi([...dimm(0, 8 * GiB), ...dimm(1, 16 * GiB), ...dimm(2, 8 * GiB)]));
  assert.deepEqual(memorySummary(three.memory, 32 * GiB, t), ["2 × 8 GiB + 16 GiB"]);
});

test("modules below 1 GiB are shown in MiB", () => {
  const hw = parseHardware(dmi(dimm(0, 512 * 2 ** 20)));
  assert.deepEqual(memorySummary(hw.memory, GiB, t), ["512 MiB"]);
});

test("speed falls back to the rated speed; a speed without a type is shown alone", () => {
  const rated = parseHardware(
    dmi([...dimm(0, 8 * GiB, ["MEMORY_DEVICE_0_TYPE=DDR5", "MEMORY_DEVICE_0_SPEED_MTS=4800"])]),
  );
  assert.equal(rated.memory.speedMts, 4800);
  const configured = parseHardware(
    dmi(dimm(0, 8 * GiB, ["MEMORY_DEVICE_0_SPEED_MTS=4800", "MEMORY_DEVICE_0_CONFIGURED_SPEED_MTS=4000"])),
  );
  assert.equal(configured.memory.speedMts, 4000);
  assert.deepEqual(memorySummary(configured.memory, 8 * GiB, t), ["4000 MT/s", "8 GiB"]);
  const noSpeed = parseHardware(dmi(dimm(0, 8 * GiB, ["MEMORY_DEVICE_0_TYPE=DDR4"])));
  assert.deepEqual(memorySummary(noSpeed.memory, 8 * GiB, t), ["DDR4", "8 GiB"]);
});

test("type, speed and manufacturer are kept only when all modules agree", () => {
  const hw = parseHardware(
    dmi([
      ...dimm(0, 8 * GiB, [
        "MEMORY_DEVICE_0_TYPE=DDR4",
        "MEMORY_DEVICE_0_SPEED_MTS=3200",
        "MEMORY_DEVICE_0_MANUFACTURER=A",
      ]),
      ...dimm(1, 8 * GiB, [
        "MEMORY_DEVICE_1_TYPE=DDR5",
        "MEMORY_DEVICE_1_SPEED_MTS=3600",
        "MEMORY_DEVICE_1_MANUFACTURER=B",
      ]),
    ]),
  );
  assert.deepEqual(hw.memory, {
    type: null,
    speedMts: null,
    manufacturer: null,
    modules: [
      { sizeBytes: 8 * GiB, locator: null },
      { sizeBytes: 8 * GiB, locator: null },
    ],
  });
});

test("modules without a size are dropped; all empty means no memory data", () => {
  assert.equal(parseHardware(dmi(["MEMORY_DEVICE_0_SIZE=0", "MEMORY_DEVICE_1_LOCATOR=X"])).memory, null);
});

test("the command never asks for serial numbers", () => {
  assert.ok(!/SERIAL/.test(HARDWARE_COMMAND));
});

test("empty output", () => {
  assert.deepEqual(parseHardware(""), { cpuModel: null, physicalCores: null, memory: null });
  assert.deepEqual(parseHardware(undefined), { cpuModel: null, physicalCores: null, memory: null });
  assert.deepEqual(parseHardware("noise\n@@other\nx\n@@cpuinfo\nno separator\n"), {
    cpuModel: null,
    physicalCores: null,
    memory: null,
  });
});
