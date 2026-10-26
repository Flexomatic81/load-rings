// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Texts and small decisions of the popup columns. t is the translator object of the calling QML file:
// t.tr(text, ...args), t.trp(singular, plural, n, ...args). A missing value gives the dash or leaves its part out.

import { formatBytes, formatCount, formatGHz, formatPercent, formatTemp } from "./format.mjs";

const DASH = "–";
const SEPARATOR = " · ";

const hasValue = (value) => typeof value === "number" && Number.isFinite(value);
const positive = (value) => hasValue(value) && value > 0;
const filled = (text) => typeof text === "string" && text !== "";

// The right end of the graphs: the newest sample, or the clock when that is later (so the newest point never
// falls off the right edge, and a pause still scrolls on).
export function graphEnd(times, clock) {
  const list = times || [];
  return list.length > 0 ? Math.max(list[list.length - 1], clock) : clock;
}

// "34 %"; the dash stays alone.
export function withUnit(text, unit) {
  return text === DASH ? DASH : `${text} ${unit}`;
}

// One decimal below ten ("0.4", "3"), whole numbers above.
export function fineNumber(value, decimalPoint) {
  if (!hasValue(value)) return DASH;
  const rounded = Math.round(value * 10) / 10;
  if (rounded >= 10) return String(Math.round(value));
  return String(rounded).replace(".", decimalPoint);
}

// Whether a tile for this value is shown: while the sensors are stale nothing is known, so the tile stays and
// shows the dash; with fresh sensors a missing value means the machine has no such sensor.
export function tileShown(value, fresh) {
  return !fresh || hasValue(value);
}

// "8 cores · 16 threads"; without the physical cores only the threads.
export function cpuTopology(physicalCores, threads, t) {
  const parts = [];
  if (positive(physicalCores)) parts.push(t.trp("%1 core", "%1 cores", physicalCores));
  if (positive(threads)) parts.push(t.trp("%1 thread", "%1 threads", threads));
  return parts.join(SEPARATOR);
}

// "2.1 · 1.8 · 1.4"
export function loadText(loadavg, decimalPoint) {
  if (!loadavg) return DASH;
  return loadavg.map((value) => (hasValue(value) ? value.toFixed(1).replace(".", decimalPoint) : DASH)).join(SEPARATOR);
}

// The line below the clock: "GHz · max 4.55".
export function clockDetail(maxMHz, t, decimalPoint) {
  return hasValue(maxMHz) ? t.tr("GHz · max %1", formatGHz(maxMHz, decimalPoint)) : "GHz";
}

// The line below the temperature: "Peak 78 °C" since the start, empty without one.
export function peakDetail(peak, t) {
  return hasValue(peak) ? t.tr("Peak %1", formatTemp(peak)) : "";
}

// The line below the core grid, from the parts there are.
export function cpuDetails(stats, ctxtPerSecond, t, decimalPoint) {
  const s = stats || {};
  const parts = [];
  if (filled(s.governor)) parts.push(t.tr("Governor %1", s.governor));
  if (filled(s.epp)) parts.push(t.tr("EPP %1", s.epp));
  if (hasValue(ctxtPerSecond)) parts.push(t.tr("%1 context switches/s", formatCount(ctxtPerSecond, decimalPoint)));
  if (hasValue(s.psiCpu)) parts.push(t.tr("Waiting for CPU %1 %", fineNumber(s.psiCpu, decimalPoint)));
  return parts.join(SEPARATOR);
}

// "Core 3 · 34 % · 63 °C · 4.12 GHz" for the core at `index` (counted from 0).
export function coreTooltip(index, core, t, decimalPoint) {
  const c = core || {};
  const parts = [t.tr("Core %1", index + 1)];
  if (hasValue(c.usage)) parts.push(`${formatPercent(c.usage, decimalPoint)} %`);
  if (hasValue(c.temperature)) parts.push(formatTemp(c.temperature));
  if (hasValue(c.frequency)) parts.push(`${formatGHz(c.frequency, decimalPoint)} GHz`);
  return parts.join(SEPARATOR);
}

// The note after the name of a consumer: "Service", "12 processes", or nothing for a single process.
export function consumerExtra(item, t) {
  if (item.kind === "service") return t.tr("Service");
  return item.processCount > 1 ? t.trp("%1 process", "%1 processes", item.processCount) : "";
}

// The value of a consumer: "2.8 %" ("percent") or "4.1 GiB" ("bytes").
export function consumerValue(item, unit, decimalPoint) {
  if (!hasValue(item.value)) return DASH;
  if (unit === "bytes") {
    const bytes = formatBytes(item.value, decimalPoint);
    return `${bytes.value} ${bytes.unit}`;
  }
  return `${fineNumber(item.value, decimalPoint)} %`;
}

// A share as the filled part of a bar, 0..1; nothing without a share.
export function barFraction(share) {
  return hasValue(share) ? Math.min(Math.max(share, 0), 1) : 0;
}
