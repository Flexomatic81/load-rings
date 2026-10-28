// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Fixed demo data for the screenshots: the sensor snapshot, fifteen minutes of load history, the kernel statistics,
// the hardware, the programs and the graphics card of an ordinary desktop (AMD Ryzen 7 5800X3D with 8 cores and
// 16 threads, DDR4-3200 as 4 × 8 GiB, AMD Radeon RX 6900 XT). No machine of anyone is read. Every run gives the
// same data; only the history is placed so that it ends at the time the scene passes in. The QML engine imports
// this module too, so the syntax stays conservative (no object spread).

import { createHistory, pushSample } from "../../package/contents/code/history.mjs";

const MIB = 1024 * 1024;
const GIB = 1024 * MIB;
// Fifteen minutes at the default interval of two seconds.
const INTERVAL_MS = 2000;
const SAMPLES = 450;

// The fonts the screenshots use, the first one available wins.
export const DEMO_FONTS = ["Noto Sans", "DejaVu Sans"];
// The files the scene writes, in this order.
export const SHOTS = [
  "panel.png",
  "panel-gpu.png",
  "panel-vertical.png",
  "panel-colors.png",
  "popup.png",
  "popup-gpu.png",
  "settings.png",
];
// The loads of the rings in panel-colors.png, from green to red.
export const COLOR_STEPS = [8, 35, 55, 78, 97];

export const DEMO_CPU = "AMD Ryzen 7 5800X3D";
export const DEMO_GPU = "AMD Radeon RX 6900 XT";
export const DEMO_GPU_ID = "gpu0";

// The values shown at the end of the history.
const CPU_NOW = 38;
const MEM_TOTAL = Math.round(31.3 * GIB);
const MEM_USED = Math.round(18.6 * GIB);
const RAM_NOW = (MEM_USED / MEM_TOTAL) * 100;
const GPU_NOW = 64;

// The first of DEMO_FONTS that is in `families`; "" when none is.
export function pickFont(families) {
  const found = DEMO_FONTS.filter((name) => families.indexOf(name) >= 0);
  return found.length > 0 ? found[0] : "";
}

// The load of the 16 logical cores; their mean is CPU_NOW.
const CORE_USAGE = [62, 18, 55, 21, 71, 25, 48, 12, 66, 30, 58, 15, 44, 27, 39, 17];

function demoCores() {
  return CORE_USAGE.map((usage, i) => ({
    usage: usage,
    frequency: 3900 + Math.round(usage * 7) + (i % 4) * 15,
    temperature: 64 + (i % 3),
  }));
}

// The sensor snapshot (the shape of SystemSensors.current) with every value present.
export function demoCurrent() {
  return {
    cpuUsage: CPU_NOW,
    cpuFrequency: 4180,
    cpuTemperature: 67,
    coreCount: CORE_USAGE.length,
    cores: demoCores(),
    memTotal: MEM_TOTAL,
    memUsed: MEM_USED,
    memApplication: Math.round(14.2 * GIB),
    memUsedPercent: RAM_NOW,
    swapTotal: 8 * GIB,
    swapUsed: Math.round(1.2 * GIB),
    gpu: {
      name: DEMO_GPU,
      usage: GPU_NOW,
      temperature: 71,
      hotspot: 86,
      memTemperature: 80,
      coreFrequency: 2250,
      memoryFrequency: 2000,
      usedVram: Math.round(9.4 * GIB),
      totalVram: 16 * GIB,
      power: 231,
      fan: 1450,
    },
  };
}

// A bump of height 1 around sample `center`, `width` samples wide.
function bump(i, center, width) {
  const d = (i - center) / width;
  return Math.exp(-d * d);
}

// A fixed sequence of numbers in [-1, 1) (a linear congruential generator).
function noise(count, seed) {
  const out = [];
  let state = seed;
  for (let i = 0; i < count; i++) {
    state = (state * 1103515245 + 12345) % 2147483648;
    out.push((state / 2147483648) * 2 - 1);
  }
  return out;
}

const clamp = (value) => Math.min(100, Math.max(0, value));

// `value`, drawn towards `target` over the last samples, so the curve ends smoothly at the value of the snapshot.
function settle(value, target, i) {
  const w = bump(i, SAMPLES - 1, 14);
  return clamp(value * (1 - w) + target * w);
}

// One sample of the history; the last one carries the values of the snapshot.
function sample(i, jitter) {
  const cpu = 16 + 4 * Math.sin(i / 9) + 4 * jitter + 30 * bump(i, 120, 25) + 58 * bump(i, 365, 28);
  const ram = 53 + (5 * i) / SAMPLES + 2 * bump(i, 365, 40);
  const gpu = 10 + 3 * jitter + 48 * bump(i, 60, 30) + 62 * bump(i, 330, 20) + 50 * bump(i, 440, 20);
  const cpuNow = settle(cpu, CPU_NOW, i);
  const gpuNow = settle(gpu, GPU_NOW, i);
  return {
    cpu: cpuNow,
    ram: settle(ram, RAM_NOW, i),
    gpu: gpuNow,
    cpuTemp: Math.round(50 + 0.45 * cpuNow),
    gpuTemp: Math.round(45 + 0.4 * gpuNow),
  };
}

// Fifteen minutes at one sample every two seconds, ending at `endMs`, for the card DEMO_GPU_ID.
export function demoHistory(endMs) {
  const jitter = noise(SAMPLES, 7);
  let history = createHistory();
  for (let i = 0; i < SAMPLES; i++) {
    const values = sample(i, jitter[i]);
    history = pushSample(history, {
      timestamp: endMs - (SAMPLES - 1 - i) * INTERVAL_MS,
      intervalMs: INTERVAL_MS,
      cpu: values.cpu,
      ram: values.ram,
      gpu: values.gpu,
      gpuId: DEMO_GPU_ID,
      cpuTemp: values.cpuTemp,
      gpuTemp: values.gpuTemp,
    });
  }
  return history;
}

// The kernel statistics (the shape of ProcStats.stats).
export function demoStats() {
  return {
    loadavg: [3.42, 2.87, 2.15],
    ctxt: 0,
    psiCpu: 1.8,
    psiMemory: 0.2,
    memFree: Math.round(4.1 * GIB),
    shmem: Math.round(0.9 * GIB),
    zram: [{ name: "zram0", orig: Math.round(1.2 * GIB), compr: Math.round(0.31 * GIB), used: Math.round(0.33 * GIB) }],
    governor: "schedutil",
    epp: "balance_performance",
  };
}

export const DEMO_CONTEXT_SWITCHES = 38400;

// The hardware (the shape of HardwareInfo.info): no manufacturer, so the memory header stays generic.
export function demoHardware() {
  const modules = [];
  for (let i = 0; i < 4; i++) modules.push({ sizeBytes: 8 * GIB, locator: "DIMM " + i });
  return {
    cpuModel: DEMO_CPU,
    physicalCores: 8,
    maxFrequency: 4550,
    memory: { type: "DDR4", speedMts: 3200, manufacturer: null, modules: modules },
  };
}

function pids(first, count) {
  const list = [];
  for (let i = 0; i < count; i++) list.push(first + i);
  return list;
}

function app(name, icon, processes, cpu, memoryGiB) {
  return {
    name: name,
    icon: icon,
    kind: "app",
    pids: pids(1000 + name.length * 100, processes),
    cpu: cpu,
    memory: Math.round(memoryGiB * GIB),
  };
}

// The programs (the shape of AppsSource.rows): KDE applications and the row of the session's background services.
export function demoApps() {
  return [
    app("Kdenlive", "kdenlive", 3, 21.4, 2.9),
    app("KDevelop", "kdevelop", 9, 8.7, 3.2),
    app("Falkon", "falkon", 14, 3.2, 4.6),
    app("digiKam", "digikam", 2, 1.1, 1.4),
    app("Kate", "kate", 1, 0.3, 0.35),
    app("Elisa", "elisa", 1, 0.4, 0.3),
    {
      name: "Background services",
      icon: "",
      kind: "service",
      pids: pids(400, 23),
      cpu: 1.6,
      memory: Math.round(1.1 * GIB),
    },
  ];
}

// The card list of the settings page (the shape of GpuChoices.options).
// Two cards, so that the card list of the settings page is enabled; the first is the one shown.
export function demoGpuOptions() {
  return [
    { text: DEMO_GPU, value: DEMO_GPU_ID },
    { text: "AMD Radeon RX 6400", value: "gpu1" },
  ];
}

// The rings of the panel (the shape of ringValues()), with or without the graphics card.
export function demoRings(withGpu) {
  const current = demoCurrent();
  const rings = [
    { key: "cpu", percent: current.cpuUsage },
    { key: "ram", percent: current.memUsedPercent },
  ];
  if (withGpu) rings.push({ key: "gpu", percent: current.gpu.usage });
  return rings;
}

// The rings of panel-colors.png: one per step of COLOR_STEPS.
export function colorRings() {
  return COLOR_STEPS.map((percent) => ({ key: "cpu", percent: percent }));
}
