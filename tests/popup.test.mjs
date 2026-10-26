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
  fineNumber,
  graphEnd,
  loadText,
  peakDetail,
  tileShown,
  withUnit,
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
  assert.equal(consumerExtra({ kind: "service", processCount: 30 }, t), "Service");
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
