// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  barFraction,
  clockDetail,
  consumerExtra,
  consumerValue,
  coreTooltip,
  cpuDetails,
  cpuTopology,
  edgeParts,
  fineNumber,
  gpuDetails,
  gpuHistoryMatches,
  graphEnd,
  legendText,
  loadText,
  memoryHeader,
  peakDetail,
  powerText,
  pressureText,
  swapShown,
  swapText,
  tileShown,
  usedLine,
  vramFraction,
  vramPercent,
  vramShown,
  vramText,
  withUnit,
  zramDevices,
  zramFraction,
  zramLabel,
  zramText,
} from "../package/contents/code/popup.mjs";

// The English fallback of the translation helpers, as the QML files pass them.
const fill = (text, args) => text.replace(/%(\d)/g, (_, d) => String(args[Number(d) - 1]));
const t = {
  tr: (text, ...args) => fill(text, args),
  trc: (context, text, ...args) => fill(text, args),
  trp: (singular, plural, n, ...args) => fill(n === 1 ? singular : plural, [n, ...args]),
};

const GiB = 2 ** 30;

test("graph end: the newest sample or the clock, whichever is later", () => {
  assert.equal(graphEnd([1000, 2000, 3000], 2500), 3000);
  assert.equal(graphEnd([1000, 2000], 9000), 9000);
  assert.equal(graphEnd([], 4000), 4000);
  assert.equal(graphEnd(undefined, 4000), 4000);
});

test("with unit: the dash stays alone", () => {
  assert.equal(withUnit("34", "%"), "34 %");
  assert.equal(withUnit("–", "%"), "–");
});

test("fine number: one decimal below ten, whole above", () => {
  assert.equal(fineNumber(3, ","), "3");
  assert.equal(fineNumber(0.42, ","), "0,4");
  assert.equal(fineNumber(9.96, "."), "10");
  assert.equal(fineNumber(14.2, "."), "14");
  assert.equal(fineNumber(NaN, "."), "–");
  assert.equal(fineNumber(null, "."), "–");
});

test("tile shown: unknown while stale, hidden when fresh and missing", () => {
  assert.equal(tileShown(63, true), true);
  assert.equal(tileShown(NaN, false), true);
  assert.equal(tileShown(NaN, true), false);
  assert.equal(tileShown(null, true), false);
});

test("cpu topology", () => {
  assert.equal(cpuTopology(8, 16, t), "8 cores · 16 threads");
  assert.equal(cpuTopology(1, 1, t), "1 core · 1 thread");
  assert.equal(cpuTopology(null, 16, t), "16 threads");
  assert.equal(cpuTopology(8, NaN, t), "8 cores");
  assert.equal(cpuTopology(null, NaN, t), "");
  assert.equal(cpuTopology(0, 0, t), "");
});

test("load averages", () => {
  assert.equal(loadText([2.13, 1.8, 1.42], ","), "2,1 · 1,8 · 1,4");
  assert.equal(loadText(null, "."), "–");
  assert.equal(loadText([2.13, null, NaN], ","), "2,1 · – · –");
  assert.equal(loadText(undefined, "."), "–");
});

test("clock detail", () => {
  assert.equal(clockDetail(4550, t, ","), "GHz · max 4,55");
  assert.equal(clockDetail(NaN, t, ","), "GHz");
});

test("peak detail", () => {
  assert.equal(peakDetail(78.2, t), "Peak 78 °C");
  assert.equal(peakDetail(null, t), "");
  // The peak is taken from the history at each interval; the tile may already show a newer, higher value.
  assert.equal(peakDetail(38, t, 44.2), "Peak 44 °C");
  assert.equal(peakDetail(78.2, t, 60), "Peak 78 °C");
  assert.equal(peakDetail(78.2, t, NaN), "Peak 78 °C");
  assert.equal(peakDetail(null, t, 44), "");
});

test("cpu details: the parts there are, joined", () => {
  const stats = { governor: "schedutil", epp: "balance_performance", psiCpu: 3 };
  assert.equal(
    cpuDetails(stats, 41234, t, "."),
    "Governor schedutil · EPP balance_performance · 41 k context switches/s · Waiting for CPU 3 %",
  );
  assert.equal(cpuDetails({ governor: null, epp: null, psiCpu: 0.4 }, NaN, t, ","), "Waiting for CPU 0,4 %");
  assert.equal(cpuDetails(null, 900, t, "."), "900 context switches/s");
  assert.equal(cpuDetails(null, NaN, t, "."), "");
  assert.equal(cpuDetails({ governor: "", epp: undefined, psiCpu: null }, null, t, "."), "");
});

test("core tooltip leaves out the missing parts", () => {
  assert.equal(
    coreTooltip(0, { usage: 34, frequency: 4120, temperature: 63.4 }, t, ","),
    "Core 1 · 34 % · 63 °C · 4,12 GHz",
  );
  assert.equal(coreTooltip(3, { usage: NaN, frequency: NaN, temperature: NaN }, t, "."), "Core 4");
  assert.equal(coreTooltip(1, { usage: 5, frequency: 3000, temperature: NaN }, t, "."), "Core 2 · 5 % · 3.00 GHz");
  assert.equal(coreTooltip(2, undefined, t, "."), "Core 3");
});

test("consumer extra", () => {
  assert.equal(consumerExtra({ kind: "app", processCount: 12 }, t), "12 processes");
  assert.equal(consumerExtra({ kind: "app", processCount: 1 }, t), "");
  assert.equal(consumerExtra({ kind: "service", processCount: 30 }, t), "30 processes");
  assert.equal(consumerExtra({ kind: "service", processCount: 1 }, t), "");
});

test("consumer value", () => {
  assert.equal(consumerValue({ value: 14.2 }, "percent", ","), "14 %");
  assert.equal(consumerValue({ value: 2.84 }, "percent", ","), "2,8 %");
  assert.equal(consumerValue({ value: 4.1 * GiB }, "bytes", ","), "4,1 GiB");
  assert.equal(consumerValue({ value: NaN }, "percent", "."), "–");
  assert.equal(consumerValue({ value: null }, "bytes", "."), "–");
});

test("bar fraction", () => {
  assert.equal(barFraction(0.25), 0.25);
  assert.equal(barFraction(1.5), 1);
  assert.equal(barFraction(-1), 0);
  assert.equal(barFraction(null), 0);
  assert.equal(barFraction(NaN), 0);
});

test("memory header: the module summary, or just the total, or nothing", () => {
  const memory = {
    type: "DDR4",
    speedMts: 3200,
    manufacturer: "A-DATA",
    modules: [{ sizeBytes: 8 * GiB }, { sizeBytes: 8 * GiB }],
  };
  assert.equal(memoryHeader(memory, 16 * GiB, t, ","), "DDR4-3200 · 2 × 8 GiB · A-DATA");
  assert.equal(memoryHeader(null, 31.3 * GiB, t, ","), "31,3 GiB");
  assert.equal(memoryHeader(undefined, 16 * GiB, t, "."), "16.0 GiB");
  assert.equal(memoryHeader(null, NaN, t, "."), "");
  assert.equal(memoryHeader(memory, NaN, t, ".").startsWith("DDR4-3200"), true);
});

test("used line: the unit is said once when both sides share it", () => {
  assert.equal(usedLine(18.6 * GiB, 31.3 * GiB, t, ","), "18,6 of 31,3 GiB used");
  assert.equal(usedLine(512 * 2 ** 20, 2 * GiB, t, "."), "512 MiB of 2.0 GiB used");
  assert.equal(usedLine(100 * 2 ** 20, 512 * 2 ** 20, t, "."), "100 of 512 MiB used");
  assert.equal(usedLine(NaN, 31 * GiB, t, "."), "–");
  assert.equal(usedLine(GiB, NaN, t, "."), "–");
  assert.equal(usedLine(null, null, t, "."), "–");
});

test("legend text names the part and gives its size", () => {
  assert.equal(legendText({ key: "apps", bytes: 16.4 * GiB }, t, ","), "Programs 16,4 GiB");
  assert.equal(legendText({ key: "other", bytes: 1.9 * GiB }, t, "."), "System 1.9 GiB");
  assert.equal(legendText({ key: "cache", bytes: 300 * 2 ** 20 }, t, "."), "Cache 300 MiB");
  assert.equal(legendText({ key: "free", bytes: 5.4 * GiB }, t, "."), "Free 5.4 GiB");
  assert.equal(legendText({ key: "available", bytes: 5.4 * GiB }, t, "."), "Available 5.4 GiB");
  assert.equal(legendText({ key: "mystery", bytes: GiB }, t, "."), "1.0 GiB");
});

test("swap: shown while unknown, hidden without swap, text and dash", () => {
  assert.equal(swapShown(8 * GiB, true), true);
  assert.equal(swapShown(0, true), false);
  assert.equal(swapShown(NaN, true), false);
  assert.equal(swapShown(NaN, false), true);
  assert.equal(swapText(0.3 * GiB, 8 * GiB, t, ","), "307 MiB of 8,0 GiB");
  assert.equal(swapText(1.5 * GiB, 8 * GiB, t, ","), "1,5 of 8,0 GiB");
  assert.equal(swapText(NaN, 8 * GiB, t, ","), "–");
  assert.equal(swapText(GiB, undefined, t, ","), "–");
});

test("zram devices: only those with something compressed", () => {
  const list = [
    { name: "zram0", orig: 1.9 * GiB, compr: 0.6 * GiB, used: 0.62 * GiB },
    { name: "zram1", orig: 0, compr: 0, used: 4096 },
  ];
  assert.deepEqual(zramDevices(list), [list[0]]);
  assert.deepEqual(zramDevices(null), []);
  assert.deepEqual(zramDevices(undefined), []);
});

test("zram text, label and bar", () => {
  const device = { name: "zram0", orig: 1.9 * GiB, compr: 1.2 * GiB, used: 0.6 * GiB };
  assert.equal(zramText(device, t, ","), "1,9 GiB → 1,2 GiB (1,6 : 1)");
  assert.equal(zramText({ orig: 0, compr: 0 }, t, "."), "");
  assert.equal(zramLabel("zram0", 1, t), "ZRAM");
  assert.equal(zramLabel("zram1", 2, t), "zram1");
  assert.ok(Math.abs(zramFraction(device, 30 * GiB) - 0.02) < 1e-9);
  assert.equal(zramFraction(device, NaN), 0);
  assert.equal(zramFraction(device, 0), 0);
});

test("pressure text", () => {
  assert.equal(pressureText(0.4, t, ","), "Waited 0,4 % of the time");
  assert.equal(pressureText(12, t, "."), "Waited 12 % of the time");
  assert.equal(pressureText(null, t, "."), "");
  assert.equal(pressureText(NaN, t, "."), "");
});

test("edge parts: the first and last part that has a size", () => {
  const parts = [{ bytes: 0 }, { bytes: 5 }, { bytes: 3 }, { bytes: 0 }];
  assert.deepEqual(edgeParts(parts), { first: 1, last: 2 });
  assert.deepEqual(edgeParts([{ bytes: 4 }]), { first: 0, last: 0 });
  assert.deepEqual(edgeParts([{ bytes: 0 }, { bytes: NaN }]), { first: -1, last: -1 });
  assert.deepEqual(edgeParts([]), { first: -1, last: -1 });
  assert.deepEqual(edgeParts(null), { first: -1, last: -1 });
});

test("gpu history matches only the card that is shown", () => {
  assert.equal(gpuHistoryMatches({ gpuId: "gpu0" }, "gpu0"), true);
  assert.equal(gpuHistoryMatches({ gpuId: "gpu0" }, "gpu1"), false);
  assert.equal(gpuHistoryMatches({ gpuId: null }, "gpu0"), false);
  assert.equal(gpuHistoryMatches({ gpuId: null }, ""), false);
  assert.equal(gpuHistoryMatches({ gpuId: "gpu0" }, ""), false);
  assert.equal(gpuHistoryMatches(null, "gpu0"), false);
});

test("power text: whole watts, the dash without a value", () => {
  assert.equal(powerText(185.6), "186 W");
  assert.equal(powerText(0), "0 W");
  assert.equal(powerText(NaN), "–");
  assert.equal(powerText(undefined), "–");
});

test("video memory: row, text and bar", () => {
  assert.equal(vramShown(NaN, false), true);
  assert.equal(vramShown(NaN, true), false);
  assert.equal(vramShown(0, true), false);
  assert.equal(vramShown(8 * GiB, true), true);
  assert.equal(vramText(6.2 * GiB, 16 * GiB, t, ","), "6,2 of 16,0 GiB");
  assert.equal(vramText(NaN, 16 * GiB, t, ","), "–");
  assert.equal(vramFraction(4 * GiB, 16 * GiB), 0.25);
  assert.equal(vramFraction(NaN, 16 * GiB), 0);
  assert.equal(vramFraction(4 * GiB, 0), 0);
  assert.equal(vramPercent(4 * GiB, 16 * GiB), 25);
  assert.ok(Number.isNaN(vramPercent(NaN, 16 * GiB)));
  assert.ok(Number.isNaN(vramPercent(4 * GiB, 0)));
  assert.ok(Number.isNaN(vramPercent(4 * GiB, NaN)));
});

test("gpu details: the parts there are, joined", () => {
  const gpu = { memoryFrequency: 1000, hotspot: 71, memTemperature: 66, fan: 1240 };
  assert.equal(gpuDetails(gpu, t, ",", "."), "Memory clock 1,00 GHz · Hotspot 71 °C · Memory 66 °C · Fan 1.240 RPM");
  assert.equal(gpuDetails(gpu, t, ".", ","), "Memory clock 1.00 GHz · Hotspot 71 °C · Memory 66 °C · Fan 1,240 RPM");
  assert.equal(gpuDetails({ fan: 0 }, t, ".", ","), "Fan 0 RPM");
  assert.equal(gpuDetails({ fan: 850 }, t, ".", ","), "Fan 850 RPM");
  assert.equal(gpuDetails({ memoryFrequency: NaN, hotspot: NaN, memTemperature: NaN, fan: NaN }, t, ".", ","), "");
  assert.equal(gpuDetails(null, t, ".", ","), "");
  // The separator is the locale's own, not a guess from the decimal point.
  assert.equal(gpuDetails({ fan: 1240 }, t, ",", ""), "Fan 1240 RPM");
  assert.equal(gpuDetails({ fan: 1240 }, t, ",", "'"), "Fan 1'240 RPM");
  assert.equal(gpuDetails({ fan: 1240 }, t, ","), "Fan 1240 RPM");
});
