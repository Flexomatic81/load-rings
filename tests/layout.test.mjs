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
  labelFit,
  labelRoom,
  MIN_READABLE_PX,
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

test("the label room is the inside of the line with a little air", () => {
  // 44 px: line centre at 20, inner edge at 18.5, two px of air on each side.
  assert.equal(labelRoom(44, 3), 33);
  // 24 px: one px of air on each side.
  assert.equal(labelRoom(24, 3), 15);
  assert.equal(labelRoom(4, 3), 0);
});

test("the label keeps its percent sign while that stays readable", () => {
  // "00%" measures 30 px and "00" 20 px at 18 px; the room is 33 px.
  assert.deepEqual(labelFit({ room: 33, fontPx: 18, withSign: 30, withoutSign: 20 }), {
    showSign: true,
    pixelSize: 18,
  });
  // A narrower room shrinks the font with the sign as long as it stays at least MIN_READABLE_PX.
  assert.deepEqual(labelFit({ room: 20, fontPx: 18, withSign: 30, withoutSign: 20 }), {
    showSign: true,
    pixelSize: 12,
  });
});

test("a small ring drops the percent sign instead of an unreadable number", () => {
  // 15 px of room: with the sign 9 px wide would need 7 px of font, without it 11 px.
  assert.deepEqual(labelFit({ room: 15, fontPx: 10, withSign: 21, withoutSign: 13 }), {
    showSign: false,
    pixelSize: 10,
  });
  assert.deepEqual(labelFit({ room: 10, fontPx: 10, withSign: 21, withoutSign: 13 }), {
    showSign: false,
    pixelSize: 7,
  });
});

test("the label never goes below 6 px and survives zero widths", () => {
  assert.equal(MIN_READABLE_PX, 9);
  assert.equal(labelFit({ room: 2, fontPx: 10, withSign: 21, withoutSign: 13 }).pixelSize, 6);
  assert.deepEqual(labelFit({ room: 20, fontPx: 10, withSign: 0, withoutSign: 0 }), { showSign: true, pixelSize: 10 });
});
