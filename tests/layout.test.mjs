// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  DEFAULT_SPACING_PX,
  MAX_RING_PX,
  MIN_RING_PX,
  RING_INSET_PX,
  RING_STROKE_PX,
  coreGridColumns,
  popupColumnWidth,
  ringLayout,
} from "../package/contents/code/layout.mjs";

test("the stroke, the inset and the diameter limits are exact", () => {
  assert.equal(RING_STROKE_PX, 3);
  assert.equal(RING_INSET_PX, 2);
  assert.equal(DEFAULT_SPACING_PX, 4);
  assert.equal(MIN_RING_PX, 16);
  assert.equal(MAX_RING_PX, 96);
});

test("a 44 px horizontal panel with two rings fills the panel height", () => {
  assert.deepEqual(ringLayout({ vertical: false, thickness: 44, count: 2, spacing: 4 }), {
    diameter: 44,
    stroke: 3,
    spacing: 4,
    fontPx: 18,
    width: 92,
    height: 44,
  });
});

test("a 30 px vertical panel with three rings stacks them", () => {
  assert.deepEqual(ringLayout({ vertical: true, thickness: 30, count: 3, spacing: 4 }), {
    diameter: 30,
    stroke: 3,
    spacing: 4,
    fontPx: 12,
    width: 30,
    height: 98,
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

test("without a spacing the default is used", () => {
  assert.equal(ringLayout({ vertical: false, thickness: 44, count: 2 }).spacing, DEFAULT_SPACING_PX);
  assert.equal(ringLayout({ vertical: false, thickness: 44, count: 2, spacing: NaN }).spacing, DEFAULT_SPACING_PX);
});

test("the font has its minimum size", () => {
  assert.deepEqual(ringLayout({ vertical: false, thickness: 10, count: 1 }), {
    diameter: 16,
    stroke: 3,
    spacing: 4,
    fontPx: 6,
    width: 16,
    height: 10,
  });
});

test("fractional sizes come out as whole pixels", () => {
  assert.deepEqual(ringLayout({ vertical: false, thickness: 44.4, count: 1, spacing: 4.4 }), {
    diameter: 44,
    stroke: 3,
    spacing: 4,
    fontPx: 18,
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
