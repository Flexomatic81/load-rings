// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Panel geometry of the rings, in pixels, and the grid of the core popup.

// The rings look like the gauges of the sibling widgets: a ring fills the panel thickness, its line is 3 px wide
// and runs 2 px inside the edge, the number takes 40 % of the size.
export const RING_STROKE_PX = 3;
export const RING_INSET_PX = 2;
// Kirigami.Units.smallSpacing at the default scale; the view passes the real value.
export const DEFAULT_SPACING_PX = 4;
export const MIN_RING_PX = 16;
export const MAX_RING_PX = 96;

const clamp = (value, low, high) => Math.min(high, Math.max(low, value));

// The size of the rings and the size of the whole row or column for a panel of the given thickness (its height
// when horizontal, its width when vertical), number of rings and spacing between them. The lengthwise size is what
// the rings need along the panel; the crosswise size is the thickness.
export function ringLayout({ vertical, thickness, count, spacing: wantedSpacing }) {
  const rings = Math.max(1, Math.round(count));
  const cross = Math.round(thickness);
  const diameter = Math.round(clamp(thickness, MIN_RING_PX, MAX_RING_PX));
  const stroke = RING_STROKE_PX;
  const spacing = Number.isFinite(wantedSpacing) ? Math.round(wantedSpacing) : DEFAULT_SPACING_PX;
  const fontPx = Math.max(6, Math.round(diameter * 0.4));
  const length = rings * diameter + (rings - 1) * spacing;
  const width = vertical ? cross : length;
  const height = vertical ? length : cross;
  return { diameter, stroke, spacing, fontPx, width, height };
}

// The number of columns of the core grid: few cores keep a narrow grid, many cores widen it.
export function coreGridColumns(count) {
  if (count <= 16) return 8;
  if (count <= 64) return 16;
  return 32;
}

// The width of a popup column in grid units.
export function popupColumnWidth(gridUnit) {
  return gridUnit * 22;
}
