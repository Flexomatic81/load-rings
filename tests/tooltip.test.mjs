// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import { tooltipLines, tooltipState } from "../package/contents/code/tooltip.mjs";

// The English fallback of the translation helpers, as the QML files pass them.
const fill = (text, args) => text.replace(/%(\d)/g, (_, d) => String(args[Number(d) - 1]));
const t = {
  tr: (text, ...args) => fill(text, args),
  trc: (context, text, ...args) => fill(text, args),
  trp: (singular, plural, n, ...args) => fill(n === 1 ? singular : plural, [n, ...args]),
};

const GiB = 2 ** 30;
const full = {
  fresh: true,
  cpu: { usage: 34, temperature: 62.6, frequency: 4120 },
  ram: { used: 18.6 * GiB, total: 31.3 * GiB, percent: 58 },
  gpu: { usage: 12, temperature: 54 },
};

test("full state: one line per part", () => {
  assert.deepEqual(tooltipLines(full, t, ","), [
    "CPU 34 % · 63 °C · 4,12 GHz",
    "RAM 18,6 of 31,3 GiB (58 %)",
    "GPU 12 % · 54 °C",
  ]);
  assert.deepEqual(tooltipLines(full, t, ".")[0], "CPU 34 % · 63 °C · 4.12 GHz");
});

test("without a graphics card there is no GPU line", () => {
  assert.deepEqual(tooltipLines({ ...full, gpu: null }, t, ","), [
    "CPU 34 % · 63 °C · 4,12 GHz",
    "RAM 18,6 of 31,3 GiB (58 %)",
  ]);
});

test("missing parts are left out", () => {
  const state = {
    fresh: true,
    cpu: { usage: 34, temperature: NaN, frequency: NaN },
    ram: { used: NaN, total: NaN, percent: 58 },
    gpu: { usage: NaN, temperature: 54 },
  };
  assert.deepEqual(tooltipLines(state, t, ","), ["CPU 34 %", "RAM 58 %", "GPU 54 °C"]);
});

test("a line without any part is dropped", () => {
  const state = {
    fresh: true,
    cpu: { usage: NaN, temperature: NaN, frequency: NaN },
    ram: { used: 4 * GiB, total: 8 * GiB, percent: NaN },
    gpu: { usage: NaN, temperature: NaN },
  };
  assert.deepEqual(tooltipLines(state, t, ","), ["RAM 4,0 of 8,0 GiB"]);
  assert.deepEqual(tooltipLines({ fresh: true, cpu: {}, ram: {}, gpu: null }, t, ","), []);
  assert.deepEqual(tooltipLines({ fresh: true }, t, ","), []);
});

test("the unit is said once when both sizes share it", () => {
  const state = { fresh: true, ram: { used: 512 * 2 ** 20, total: 8 * GiB, percent: 6 } };
  assert.deepEqual(tooltipLines(state, t, "."), ["RAM 512 MiB of 8.0 GiB (6 %)"]);
});

test("stale sensors give one line", () => {
  assert.deepEqual(tooltipLines({ ...full, fresh: false }, t, ","), ["No data from the system sensors"]);
});

test("the state is built from the freshness and the snapshot", () => {
  const current = {
    cpuUsage: 34,
    cpuTemperature: 62.6,
    cpuFrequency: 4120,
    memUsed: 5,
    memTotal: 10,
    memUsedPercent: 50,
    gpu: { usage: 12, temperature: 54 },
  };
  assert.deepEqual(tooltipState(true, current, true), {
    fresh: true,
    cpu: { usage: 34, temperature: 62.6, frequency: 4120 },
    ram: { used: 5, total: 10, percent: 50 },
    gpu: { usage: 12, temperature: 54 },
  });
  assert.equal(tooltipState(true, current, false).gpu, null);
  assert.equal(tooltipState(false, current, true).fresh, false);
  assert.deepEqual(tooltipState(true, {}, true).cpu, {
    usage: undefined,
    temperature: undefined,
    frequency: undefined,
  });
  assert.deepEqual(tooltipState(true, current, true).gpu.usage, 12);
  assert.deepEqual(tooltipState(true, { gpu: undefined }, true).gpu, { usage: undefined, temperature: undefined });
});

test("a missing snapshot gives an empty state", () => {
  assert.deepEqual(tooltipLines(tooltipState(true, undefined, true), t, ","), []);
});
