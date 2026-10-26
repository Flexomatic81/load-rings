// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Texts and small decisions of the popup columns. t is the translator object of the calling QML file:
// t.tr(text, ...args), t.trp(singular, plural, n, ...args). A missing value gives the dash or leaves its part out.

import { formatBytes, formatCount, formatGHz, formatPercent, formatTemp } from "./format.mjs";
import { memorySummary } from "./hardware.mjs";
import { zramRatio } from "./memory.mjs";

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

// The head of the memory column: "DDR4-3200 · 4 × 8 GiB · A-DATA", only the total without module data, nothing
// while the total is unknown too.
export function memoryHeader(memory, totalBytes, t, decimalPoint) {
  if (!memory && !hasValue(totalBytes)) return "";
  return memorySummary(memory, totalBytes, t, decimalPoint).join(SEPARATOR);
}

// Two sizes for "x of y": the unit of the first is left out when both share it ("18.6 of 31.3 GiB").
function sizePair(first, second, decimalPoint) {
  const a = formatBytes(first, decimalPoint);
  const b = formatBytes(second, decimalPoint);
  return [a.unit === b.unit ? a.value : `${a.value} ${a.unit}`, `${b.value} ${b.unit}`];
}

// "18.6 of 31.3 GiB used"; the dash when either size is unknown.
export function usedLine(used, total, t, decimalPoint) {
  if (!hasValue(used) || !hasValue(total)) return DASH;
  const [a, b] = sizePair(used, total, decimalPoint);
  return t.tr("%1 of %2 used", a, b);
}

function segmentLabel(key, t) {
  switch (key) {
    case "apps":
      return t.tr("Programs");
    case "other":
      return t.tr("System");
    case "cache":
      return t.tr("Cache");
    case "free":
      return t.tr("Free");
    case "available":
      return t.tr("Available");
    default:
      return "";
  }
}

// The legend entry of a memory bar segment: "Programs 16.4 GiB".
export function legendText(segment, t, decimalPoint) {
  const size = formatBytes(segment.bytes, decimalPoint);
  return [segmentLabel(segment.key, t), `${size.value} ${size.unit}`].filter(filled).join(" ");
}

// Whether the swap row is shown: unknown while stale, hidden on a machine without swap.
export function swapShown(swapTotal, fresh) {
  return !fresh || positive(swapTotal);
}

// "0.3 of 8.0 GiB"; the dash when either size is unknown.
export function swapText(used, total, t, decimalPoint) {
  if (!hasValue(used) || !hasValue(total)) return DASH;
  const [a, b] = sizePair(used, total, decimalPoint);
  return t.trc("@label amount used of total", "%1 of %2", a, b);
}

// The ZRAM devices that hold something; an idle one has nothing to show.
export function zramDevices(devices) {
  return (devices || []).filter((device) => zramRatio(device) !== null);
}

// "1.9 GiB → 0.6 GiB (3.2 : 1)"; empty for an idle device.
export function zramText(device, t, decimalPoint) {
  const ratio = zramRatio(device);
  if (ratio === null) return "";
  const orig = formatBytes(device.orig, decimalPoint);
  const compr = formatBytes(device.compr, decimalPoint);
  return t.tr(
    "%1 → %2 (%3 : 1)",
    `${orig.value} ${orig.unit}`,
    `${compr.value} ${compr.unit}`,
    String(ratio).replace(".", decimalPoint),
  );
}

// "ZRAM" for the usual single device, the device name when there are several.
export function zramLabel(name, count, t) {
  return count > 1 ? name : t.tr("ZRAM");
}

// The part of the memory the device itself takes up, 0..1.
export function zramFraction(device, memTotal) {
  return positive(memTotal) && hasValue(device.used) ? device.used / memTotal : 0;
}

// "Waited 0.4 % of the time"; empty without pressure information.
export function pressureText(psi, t, decimalPoint) {
  return hasValue(psi) ? t.tr("Waited %1 % of the time", fineNumber(psi, decimalPoint)) : "";
}

// The first and last part of a bar that has a size ({ first, last }, -1 when none): only these two get rounded
// outer corners.
export function edgeParts(segments) {
  const list = segments || [];
  const sized = list.map((segment, i) => (positive(segment.bytes) ? i : -1)).filter((i) => i >= 0);
  return sized.length > 0 ? { first: sized[0], last: sized[sized.length - 1] } : { first: -1, last: -1 };
}

// Whether the history holds the card that is shown now; otherwise its graph and peak belong to another card.
export function gpuHistoryMatches(history, gpuId) {
  return gpuId !== "" && (history || {}).gpuId === gpuId;
}

// "186 W"; the dash without a value.
export function powerText(watts) {
  return hasValue(watts) ? `${Math.round(watts)} W` : DASH;
}

// The video memory row follows the rules of the swap row, and reads like it ("6.2 of 16.0 GiB").
export function vramShown(total, fresh) {
  return swapShown(total, fresh);
}

export function vramText(used, total, t, decimalPoint) {
  return swapText(used, total, t, decimalPoint);
}

// The used part of the video memory, 0..1.
export function vramFraction(used, total) {
  return positive(total) && hasValue(used) ? used / total : 0;
}

// The used part of the video memory in percent (for the bar color); NaN when it is unknown.
export function vramPercent(used, total) {
  return positive(total) && hasValue(used) ? (used / total) * 100 : NaN;
}

// A whole number with the locale's thousands separator ("1,240"); without one the digits stay together.
function grouped(n, separator) {
  return String(Math.round(n)).replace(/\B(?=(\d{3})+$)/g, separator);
}

// The line below the graphics card figures, from the parts there are:
// "Memory clock 1.00 GHz · Hotspot 71 °C · Memory 66 °C · Fan 1,240 RPM". A fan at 0 RPM is a value.
export function gpuDetails(gpu, t, decimalPoint, groupSeparator = "") {
  const g = gpu || {};
  const parts = [];
  if (hasValue(g.memoryFrequency)) parts.push(t.tr("Memory clock %1 GHz", formatGHz(g.memoryFrequency, decimalPoint)));
  if (hasValue(g.hotspot)) parts.push(t.tr("Hotspot %1", formatTemp(g.hotspot)));
  if (hasValue(g.memTemperature))
    parts.push(t.trc("@label temperature of the graphics memory", "Memory %1", formatTemp(g.memTemperature)));
  if (hasValue(g.fan)) parts.push(t.tr("Fan %1 RPM", grouped(g.fan, groupSeparator)));
  return parts.join(SEPARATOR);
}
