// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import { RING_STOPS, ringColor } from "../package/contents/code/color.mjs";

test("the stops are exact", () => {
  assert.equal(ringColor(0), "#27ae60");
  assert.equal(ringColor(50), "#fdbc4b");
  assert.equal(ringColor(75), "#f67400");
  assert.equal(ringColor(100), "#da4453");
});

test("the stop table lists the four load colors", () => {
  assert.deepEqual(RING_STOPS, [
    [0, "#27ae60"],
    [50, "#fdbc4b"],
    [75, "#f67400"],
    [100, "#da4453"],
  ]);
});

test("between two stops the color is interpolated per channel and rounded", () => {
  assert.equal(ringColor(25), "#92b556");
});

test("out of range is clamped", () => {
  assert.equal(ringColor(-5), "#27ae60");
  assert.equal(ringColor(140), "#da4453");
});

test("no value gives no color", () => {
  for (const v of [null, undefined, NaN, Infinity, -Infinity]) assert.equal(ringColor(v), null);
});
