// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The one-time hardware query: processor model, physical core count and the
// memory modules. Serial numbers are never requested.

import { formatBytes } from "./format.mjs";

const GIB = 2 ** 30;

// One line for the shell. Each part may fail without hiding the other.
export const HARDWARE_COMMAND =
  "echo @@cpuinfo; grep -E '^(model name|physical id|core id)' /proc/cpuinfo 2>/dev/null; " +
  "echo @@cpufreq; cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null; " +
  "echo @@dmi; udevadm info --query=property /sys/devices/virtual/dmi/id 2>/dev/null | " +
  "grep -E '^MEMORY_DEVICE_[0-9]+_(SIZE|TYPE|SPEED_MTS|CONFIGURED_SPEED_MTS|MANUFACTURER|LOCATOR)='; true";

const ABSENT = new Set(["", "unknown", "not specified", "undefined"]);

// The value, or null when firmware left it out.
const known = (value) => (ABSENT.has(value.trim().toLowerCase()) ? null : value.trim());

const cleanModel = (name) =>
  name
    .replace(/\(R\)|\(TM\)/g, "")
    .replace(/\s+\d+-Core Processor$/, "")
    .replace(/\s+/g, " ")
    .trim();

function parseCpu(lines) {
  let model = null;
  let physical = "";
  const cores = new Set();
  for (const line of lines) {
    const sep = line.indexOf(":");
    if (sep < 0) continue;
    const key = line.slice(0, sep).trim();
    const value = line.slice(sep + 1).trim();
    if (key === "model name" && model === null && value !== "") model = cleanModel(value);
    else if (key === "physical id") physical = value;
    else if (key === "core id") cores.add(`${physical}/${value}`);
  }
  return { cpuModel: model, physicalCores: cores.size > 0 ? cores.size : null };
}

// The value shared by all modules, or null when they differ or none has one.
function common(values) {
  const first = values[0];
  return first !== undefined && values.every((v) => v === first) ? first : null;
}

function parseMemory(lines) {
  const devices = new Map();
  for (const line of lines) {
    const m = /^MEMORY_DEVICE_(\d+)_([A-Z_]+)=(.*)$/.exec(line);
    if (m === null) continue;
    const device = devices.get(m[1]) ?? {};
    device[m[2]] = m[3];
    devices.set(m[1], device);
  }
  const present = [...devices.entries()]
    .sort((a, b) => Number(a[0]) - Number(b[0]))
    .map((e) => e[1])
    .filter((d) => Number(d.SIZE) > 0);
  if (present.length === 0) return null;
  const speeds = present.map((d) => known(d.CONFIGURED_SPEED_MTS ?? "") ?? known(d.SPEED_MTS ?? ""));
  const speed = common(speeds);
  return {
    type: common(present.map((d) => known(d.TYPE ?? ""))),
    speedMts: speed === null ? null : Number(speed),
    manufacturer: common(present.map((d) => known(d.MANUFACTURER ?? ""))),
    modules: present.map((d) => ({ sizeBytes: Number(d.SIZE), locator: known(d.LOCATOR ?? "") })),
  };
}

// stdout of HARDWARE_COMMAND -> what could be read; missing parts are null.
export function parseHardware(stdout) {
  const sections = { cpuinfo: [], cpufreq: [], dmi: [] };
  let current = null;
  for (const line of String(stdout ?? "").split("\n")) {
    if (line.startsWith("@@")) current = sections[line.slice(2).trim()] ?? null;
    else if (current !== null) current.push(line);
  }
  const cpu = parseCpu(sections.cpuinfo);
  return {
    cpuModel: cpu.cpuModel,
    physicalCores: cpu.physicalCores,
    maxFrequency: parseMaxFrequency(sections.cpufreq),
    memory: parseMemory(sections.dmi),
  };
}

// The highest clock the processor reaches, from cpufreq in kHz, in MHz; null without cpufreq. (The sensor
// cpu/all/maximumFrequency is the fastest core at the moment, not this.)
function parseMaxFrequency(lines) {
  const khz = Number((lines[0] ?? "").trim());
  return Number.isFinite(khz) && khz > 0 ? Math.round(khz / 1000) : null;
}

function moduleSize(bytes, decimalPoint) {
  if (bytes < GIB) {
    const mib = formatBytes(bytes, decimalPoint);
    return `${mib.value} ${mib.unit}`;
  }
  return `${Math.round(bytes / GIB)} GiB`;
}

// Module sizes grouped by size in order of first appearance: "4 × 8 GiB",
// "8 GiB + 16 GiB". t is the translator object; only t.tr(text, ...args) -> string is used.
function sizeSummary(modules, t, decimalPoint) {
  const counts = new Map();
  for (const m of modules) counts.set(m.sizeBytes, (counts.get(m.sizeBytes) ?? 0) + 1);
  return [...counts.entries()]
    .map(([bytes, n]) => {
      const size = moduleSize(bytes, decimalPoint);
      return n > 1 ? t.tr("%1 × %2", n, size) : size;
    })
    .join(" + ");
}

// Parts for the memory column header, e.g. ["DDR4-3200", "4 × 8 GiB", "A-DATA"].
// Without module data only the total is returned.
export function memorySummary(memory, totalBytes, t, decimalPoint = ".") {
  if (memory === null || memory === undefined) {
    const total = formatBytes(totalBytes, decimalPoint);
    return [`${total.value} ${total.unit}`];
  }
  const parts = [];
  const speed = memory.speedMts === null ? null : `${memory.speedMts}`;
  if (memory.type !== null && speed !== null) parts.push(`${memory.type}-${speed}`);
  else if (memory.type !== null) parts.push(memory.type);
  else if (speed !== null) parts.push(`${speed} MT/s`);
  parts.push(sizeSummary(memory.modules, t, decimalPoint));
  if (memory.manufacturer !== null) parts.push(memory.manufacturer);
  return parts;
}
