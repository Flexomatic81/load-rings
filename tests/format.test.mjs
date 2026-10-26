// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  formatBytes,
  formatCount,
  formatGHz,
  formatPercent,
  formatTemp,
  ringText,
} from "../package/contents/code/format.mjs";

const GiB = 2 ** 30,
  MiB = 2 ** 20;

test("ring text", () => {
  assert.equal(ringText(34.4), "34");
  assert.equal(ringText(99.6), "100");
  assert.equal(ringText(130), "100");
  assert.equal(ringText(-5), "0");
  assert.equal(ringText(null), "–");
  assert.equal(ringText(undefined), "–");
  assert.equal(ringText(NaN), "–");
});

test("percent", () => {
  assert.equal(formatPercent(34.4, ","), "34");
  assert.equal(formatPercent(250, ","), "100");
  assert.equal(formatPercent(null, ","), "–");
});

test("bytes", () => {
  assert.deepEqual(formatBytes(18.6 * GiB, ","), { value: "18,6", unit: "GiB" });
  assert.deepEqual(formatBytes(18.6 * GiB, "."), { value: "18.6", unit: "GiB" });
  assert.deepEqual(formatBytes(680 * MiB, ","), { value: "680", unit: "MiB" });
  assert.deepEqual(formatBytes(GiB, ","), { value: "1,0", unit: "GiB" });
  assert.deepEqual(formatBytes(null, ","), { value: "–", unit: "MiB" });
});

test("clock, temperature, counts", () => {
  assert.equal(formatGHz(4120, ","), "4,12");
  assert.equal(formatGHz(null, ","), "–");
  assert.equal(formatTemp(62.6), "63 °C");
  assert.equal(formatTemp(null), "–");
  assert.equal(formatCount(950, ","), "950");
  assert.equal(formatCount(41234, ","), "41 k");
  assert.equal(formatCount(1234567, ","), "1,2 M");
  assert.equal(formatCount(null, ","), "–");
});
