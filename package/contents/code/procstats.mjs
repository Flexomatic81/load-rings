// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Kernel statistics that are read only while the popup is open: load average,
// context switches, pressure stall information, free and shared memory, ZRAM
// and the CPU frequency governor.

const SYSFS_CPU = "/sys/devices/system/cpu/cpu0/cpufreq";

// One line for the shell. Every read hides its error; a missing file leaves
// its section empty.
export const STATS_COMMAND =
  "echo @@loadavg; cat /proc/loadavg 2>/dev/null; " +
  "echo @@stat; grep '^ctxt ' /proc/stat 2>/dev/null; " +
  "echo @@psi_cpu; cat /proc/pressure/cpu 2>/dev/null; " +
  "echo @@psi_memory; cat /proc/pressure/memory 2>/dev/null; " +
  "echo @@meminfo; grep -E '^(MemFree|Shmem):' /proc/meminfo 2>/dev/null; " +
  "echo @@zram; for d in /sys/block/zram*; do " +
  '[ -r "$d/mm_stat" ] && echo "$(basename "$d") $(cat "$d/mm_stat" 2>/dev/null)"; done 2>/dev/null; ' +
  `echo @@governor; cat ${SYSFS_CPU}/scaling_governor 2>/dev/null; ` +
  `echo @@epp; cat ${SYSFS_CPU}/energy_performance_preference 2>/dev/null; true`;

const MAX_RATE_GAP_MS = 30000;

// The number in text, or null when it is not a plain non-negative number.
function number(text) {
  if (text === undefined || !/^\d+(\.\d+)?$/.test(text)) return null;
  return Number(text);
}

// Splits the output at the "@@name" lines into { name: [lines] }.
function sections(stdout) {
  const result = {};
  let current = null;
  for (const raw of stdout.split("\n")) {
    const line = raw.trim();
    if (line.startsWith("@@")) {
      current = line.slice(2);
      result[current] = [];
    } else if (current !== null && line !== "") {
      result[current].push(line);
    }
  }
  return result;
}

function parseLoadavg(lines) {
  if (!lines || lines.length === 0) return null;
  const fields = lines[0].split(/\s+/).slice(0, 3).map(number);
  return fields.length === 3 && fields.every((f) => f !== null) ? fields : null;
}

function parseCtxt(lines) {
  if (!lines || lines.length === 0) return null;
  const fields = lines[0].split(/\s+/);
  return fields[0] === "ctxt" ? number(fields[1]) : null;
}

// avg10 of the "some" line.
function parsePsi(lines) {
  if (!lines) return null;
  for (const line of lines) {
    const fields = line.split(/\s+/);
    if (fields[0] !== "some") continue;
    for (const field of fields) {
      if (field.startsWith("avg10=")) return number(field.slice(6));
    }
  }
  return null;
}

// Bytes of the "Key:   n kB" line, or null.
function kibibytes(lines, key) {
  if (!lines) return null;
  for (const line of lines) {
    const fields = line.split(/\s+/);
    if (fields[0] === key + ":" && fields[2] === "kB") {
      const value = number(fields[1]);
      return value === null ? null : value * 1024;
    }
  }
  return null;
}

function parseZram(lines) {
  const devices = [];
  for (const line of lines || []) {
    const fields = line.split(/\s+/);
    const orig = number(fields[1]);
    const compr = number(fields[2]);
    const used = number(fields[3]);
    if (fields[0].startsWith("zram") && orig !== null && compr !== null && used !== null) {
      devices.push({ name: fields[0], orig: orig, compr: compr, used: used });
    }
  }
  return devices;
}

function firstLine(lines) {
  return lines && lines.length > 0 ? lines[0] : null;
}

export function parseStats(stdout) {
  const s = sections(stdout);
  return {
    loadavg: parseLoadavg(s.loadavg),
    ctxt: parseCtxt(s.stat),
    psiCpu: parsePsi(s.psi_cpu),
    psiMemory: parsePsi(s.psi_memory),
    memFree: kibibytes(s.meminfo, "MemFree"),
    shmem: kibibytes(s.meminfo, "Shmem"),
    zram: parseZram(s.zram),
    governor: firstLine(s.governor),
    epp: firstLine(s.epp),
  };
}

// Context switches per second between two readings, or null when there is
// nothing to compare (no previous reading, counter reset, gap too small or
// too large).
export function ctxtRate(prev, next) {
  if (prev === null || prev === undefined) return null;
  const elapsed = next.timestamp - prev.timestamp;
  if (next.ctxt < prev.ctxt || elapsed <= 0 || elapsed > MAX_RATE_GAP_MS) return null;
  return ((next.ctxt - prev.ctxt) * 1000) / elapsed;
}
