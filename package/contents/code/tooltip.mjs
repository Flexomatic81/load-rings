// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The lines of the panel tooltip. t is the translator object of the calling QML file (t.tr); a part without a
// value is left out, and a line without any part is dropped.

import { formatGHz, formatPercent, formatTemp } from "./format.mjs";
import { sizePair } from "./popup.mjs";

const SEPARATOR = " · ";

const hasValue = (value) => typeof value === "number" && Number.isFinite(value);

// What the tooltip reads from the sensors: whether they are fresh, the snapshot and whether a card is shown.
export function tooltipState(fresh, current, gpuShown) {
  const c = current || {};
  const gpu = c.gpu || {};
  return {
    fresh,
    cpu: { usage: c.cpuUsage, temperature: c.cpuTemperature, frequency: c.cpuFrequency },
    ram: { used: c.memUsed, total: c.memTotal, percent: c.memUsedPercent },
    gpu: gpuShown ? { usage: gpu.usage, temperature: gpu.temperature } : null,
  };
}

const percentText = (value) => `${formatPercent(value)} %`;

function cpuLine(cpu, t, decimalPoint) {
  const parts = [];
  if (hasValue(cpu.usage)) parts.push(percentText(cpu.usage));
  if (hasValue(cpu.temperature)) parts.push(formatTemp(cpu.temperature));
  if (hasValue(cpu.frequency)) parts.push(`${formatGHz(cpu.frequency, decimalPoint)} GHz`);
  return parts.length > 0 ? t.tr("CPU %1", parts.join(SEPARATOR)) : "";
}

function ramLine(ram, t, decimalPoint) {
  const parts = [];
  if (hasValue(ram.used) && hasValue(ram.total)) {
    const [used, total] = sizePair(ram.used, ram.total, decimalPoint);
    parts.push(t.trc("@label amount used of total", "%1 of %2", used, total));
  }
  if (hasValue(ram.percent)) parts.push(parts.length > 0 ? `(${percentText(ram.percent)})` : percentText(ram.percent));
  return parts.length > 0 ? t.tr("RAM %1", parts.join(" ")) : "";
}

function gpuLine(gpu, t) {
  const parts = [];
  if (hasValue(gpu.usage)) parts.push(percentText(gpu.usage));
  if (hasValue(gpu.temperature)) parts.push(formatTemp(gpu.temperature));
  return parts.length > 0 ? t.tr("GPU %1", parts.join(SEPARATOR)) : "";
}

// state: { fresh, cpu: { usage, temperature, frequency }, ram: { used, total, percent }, gpu: { usage, temperature }
// or null }. Stale sensors give the one line that says so.
export function tooltipLines(state, t, decimalPoint) {
  if (!state.fresh) return [t.tr("No data from the system sensors")];
  const lines = [cpuLine(state.cpu || {}, t, decimalPoint), ramLine(state.ram || {}, t, decimalPoint)];
  if (state.gpu) lines.push(gpuLine(state.gpu, t));
  return lines.filter((line) => line !== "");
}
