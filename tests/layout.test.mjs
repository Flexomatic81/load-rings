// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  MAX_RING_PX,
  MIN_RING_PX,
  RING_MARGIN_PX,
  coreGridColumns,
  popupColumnWidth,
  ringLayout,
} from "../package/contents/code/layout.mjs";

test("the margin and the diameter limits are exact", () => {
  assert.equal(RING_MARGIN_PX, 2);
  assert.equal(MIN_RING_PX, 16);
  assert.equal(MAX_RING_PX, 96);
});

test("a 44 px horizontal panel with two rings", () => {
  assert.deepEqual(ringLayout({ vertical: false, thickness: 44, count: 2 }), {
    diameter: 40,
    stroke: 4,
    spacing: 8,
    fontPx: 13,
    width: 92,
    height: 44,
  });
});

test("a 30 px vertical panel with three rings stacks them", () => {
  assert.deepEqual(ringLayout({ vertical: true, thickness: 30, count: 3 }), {
    diameter: 26,
    stroke: 3,
    spacing: 5,
    fontPx: 8,
    width: 30,
    height: 92,
  });
});

test("the diameter is clamped", () => {
  assert.equal(ringLayout({ vertical: false, thickness: 10, count: 1 }).diameter, 16);
  assert.equal(ringLayout({ vertical: false, thickness: 300, count: 1 }).diameter, 96);
});

test("a count below one is laid out as one ring", () => {
  assert.deepEqual(
    ringLayout({ vertical: false, thickness: 44, count: 0 }),
    ringLayout({ vertical: false, thickness: 44, count: 1 }),
  );
});

test("the stroke, spacing and font have their minimum values", () => {
  assert.deepEqual(ringLayout({ vertical: false, thickness: 10, count: 1 }), {
    diameter: 16,
    stroke: 2,
    spacing: 3,
    fontPx: 6,
    width: 20,
    height: 10,
  });
});

test("fractional sizes come out as whole pixels", () => {
  assert.deepEqual(ringLayout({ vertical: false, thickness: 44.4, count: 1 }), {
    diameter: 40,
    stroke: 4,
    spacing: 8,
    fontPx: 13,
    width: 44,
    height: 44,
  });
});

test("the core grid widens for many cores", () => {
  assert.equal(coreGridColumns(16), 8);
  assert.equal(coreGridColumns(24), 16);
  assert.equal(coreGridColumns(128), 32);
});

test("the popup column width is 22 grid units", () => {
  assert.equal(popupColumnWidth(3), 66);
});
