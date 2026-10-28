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

// Below this font size the number of a ring is shown without its percent sign, so it stays readable.
export const MIN_READABLE_PX = 9;
const MIN_LABEL_PX = 6;

// The width the label may take inside the ring line: the inner edge of the line, less some air on each side (one
// pixel on small rings, about 5 % of the ring on larger ones).
export function labelRoom(diameter, stroke) {
  const inner = diameter - 2 * RING_INSET_PX - stroke;
  const air = Math.max(1, Math.round(diameter * 0.05));
  return Math.max(0, inner - 2 * air);
}

// The font size that makes a text of the given width (measured at fontPx) fit the room.
function fitted(room, fontPx, width) {
  return width > room ? Math.floor((fontPx * room) / width) : fontPx;
}

// How the ring number is set: with its percent sign while that stays readable, otherwise without it and larger.
// withSign and withoutSign are the widths of the widest two-digit label ("00%" and "00") at fontPx, so every ring of
// one size gets the same answer whatever its load.
export function labelFit({ room, fontPx, withSign, withoutSign }) {
  const sized = fitted(room, fontPx, withSign);
  if (sized >= MIN_READABLE_PX) return { showSign: true, pixelSize: sized };
  return { showSign: false, pixelSize: Math.max(MIN_LABEL_PX, fitted(room, fontPx, withoutSign)) };
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
