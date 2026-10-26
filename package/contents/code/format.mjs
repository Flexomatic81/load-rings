// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Number formatting for the rings and the popup. A missing value gives the dash.

const DASH = "–";
const MIB = 2 ** 20;
const GIB = 2 ** 30;

const hasValue = (value) => typeof value === "number" && Number.isFinite(value);

const withPoint = (text, decimalPoint) => text.replace(".", decimalPoint);

// The rounded load for the ring center, 0..100.
export function ringText(percent) {
  if (!hasValue(percent)) return DASH;
  return String(Math.round(Math.min(100, Math.max(0, percent))));
}

// Whole percent. The decimal point is unused for whole numbers and kept for symmetry with the other formatters.
// eslint-disable-next-line no-unused-vars -- API symmetry
export function formatPercent(value, decimalPoint) {
  return ringText(value);
}

// Below 1 GiB whole MiB, otherwise GiB with one decimal.
export function formatBytes(bytes, decimalPoint) {
  if (!hasValue(bytes)) return { value: DASH, unit: "MiB" };
  if (bytes < GIB) return { value: String(Math.round(bytes / MIB)), unit: "MiB" };
  return { value: withPoint((bytes / GIB).toFixed(1), decimalPoint), unit: "GiB" };
}

// A clock in MHz as GHz with two decimals.
export function formatGHz(mhz, decimalPoint) {
  if (!hasValue(mhz)) return DASH;
  return withPoint((mhz / 1000).toFixed(2), decimalPoint);
}

export function formatTemp(celsius) {
  if (!hasValue(celsius)) return DASH;
  return `${Math.round(celsius)} °C`;
}

// Below 1000 whole, below a million in thousands ("41 k"), otherwise in millions with one decimal.
export function formatCount(n, decimalPoint) {
  if (!hasValue(n)) return DASH;
  if (n < 1000) return String(Math.round(n));
  if (n < 1e6) return `${Math.round(n / 1000)} k`;
  return `${withPoint((n / 1e6).toFixed(1), decimalPoint)} M`;
}
