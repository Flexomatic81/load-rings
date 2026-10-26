// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Ring colors: green at low load, red at full load, interpolated linearly between the stops.

export const RING_STOPS = [
  [0, "#27ae60"],
  [50, "#fdbc4b"],
  [75, "#f67400"],
  [100, "#da4453"],
];

function channels(hex) {
  return [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
}

function hexOf(rgb) {
  return `#${rgb.map((v) => v.toString(16).padStart(2, "0")).join("")}`;
}

// The color of a load in percent (clamped to 0 to 100) as "#rrggbb", or null when there is no value.
export function ringColor(percent) {
  if (!Number.isFinite(percent)) return null;
  const value = Math.min(100, Math.max(0, percent));
  const upper = RING_STOPS.findIndex(([at]) => value <= at);
  if (upper === 0) return RING_STOPS[0][1];
  const [fromAt, fromHex] = RING_STOPS[upper - 1];
  const [toAt, toHex] = RING_STOPS[upper];
  const t = (value - fromAt) / (toAt - fromAt);
  const from = channels(fromHex);
  const to = channels(toHex);
  return hexOf(from.map((a, i) => Math.round(a + (to[i] - a) * t)));
}
