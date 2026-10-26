// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Panel geometry of the rings, in pixels, and the grid of the core popup.

export const RING_MARGIN_PX = 2;
export const MIN_RING_PX = 16;
export const MAX_RING_PX = 96;

const clamp = (value, low, high) => Math.min(high, Math.max(low, value));

// The size of the rings and the size of the whole row or column for a panel of the given thickness (its height
// when horizontal, its width when vertical) and number of rings. The lengthwise size is what the rings need along
// the panel; the crosswise size is the thickness.
export function ringLayout({ vertical, thickness, count }) {
  const rings = Math.max(1, Math.round(count));
  const cross = Math.round(thickness);
  const diameter = Math.round(clamp(thickness - 2 * RING_MARGIN_PX, MIN_RING_PX, MAX_RING_PX));
  const stroke = Math.max(2, Math.round(diameter * 0.11));
  const spacing = Math.max(2, Math.round(diameter * 0.2));
  const fontPx = Math.max(6, Math.floor(diameter * 0.34));
  const length = rings * diameter + (rings - 1) * spacing + 2 * RING_MARGIN_PX;
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
