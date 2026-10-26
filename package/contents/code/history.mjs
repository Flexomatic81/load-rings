// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The load history kept in memory for the graphs: up to one hour of samples, plus the temperature peaks since the
// start. All functions are pure; a history is replaced, never changed.

export const VALID_MINUTES = [1, 5, 15, 60];
export const HISTORY_MS = 3_600_000;
// One hour at the shortest interval (0.5 s), whatever interval is set.
export const MAX_SAMPLES = 7201;

const DEFAULT_MINUTES = 5;
// A pause longer than this many intervals shows as a gap.
const GAP_FACTOR = 3;

export function validMinutes(value) {
  return VALID_MINUTES.includes(value) ? value : DEFAULT_MINUTES;
}

export function createHistory() {
  return {
    times: [],
    intervals: [],
    cpu: [],
    ram: [],
    gpu: [],
    gpuId: null,
    peakCpuTemp: null,
    peakGpuTemp: null,
  };
}

// Another card (or none; an empty id means none) must not inherit the values of the previous one.
export function selectGpu(history, gpuId) {
  const id = gpuId || null;
  if (history.gpuId === id) {
    return history;
  }
  return Object.assign({}, history, { gpu: history.gpu.map(() => null), gpuId: id, peakGpuTemp: null });
}

function peak(previous, value) {
  if (value === null || value === undefined || !Number.isFinite(value)) {
    return previous;
  }
  return previous === null ? value : Math.max(previous, value);
}

function finiteOrNull(value) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

export function pushSample(history, sample) {
  const base = selectGpu(history, sample.gpuId);
  const cutoff = sample.timestamp - HISTORY_MS;
  let first = 0;
  while (first < base.times.length && base.times[first] < cutoff) {
    first += 1;
  }
  first = Math.max(first, base.times.length + 1 - MAX_SAMPLES);
  const keep = (list, value) => [...list.slice(first), value];
  return {
    times: keep(base.times, sample.timestamp),
    intervals: keep(base.intervals, sample.intervalMs),
    cpu: keep(base.cpu, finiteOrNull(sample.cpu)),
    ram: keep(base.ram, finiteOrNull(sample.ram)),
    gpu: keep(base.gpu, finiteOrNull(sample.gpu)),
    gpuId: base.gpuId,
    peakCpuTemp: peak(base.peakCpuTemp, sample.cpuTemp),
    peakGpuTemp: peak(base.peakGpuTemp, sample.gpuTemp),
  };
}

// The points of the last `minutes` minutes before `now`. A null point (with a time between its neighbours) marks a
// pause longer than three intervals; the larger of the two neighbouring intervals counts, so a change of the
// interval makes no false gap.
export function windowOf(history, minutes, now) {
  const from = now - minutes * 60_000;
  const out = { times: [], cpu: [], ram: [], gpu: [] };
  let last = -1;
  history.times.forEach((time, i) => {
    if (time < from) {
      return;
    }
    if (last >= 0) {
      const limit = GAP_FACTOR * Math.max(history.intervals[last], history.intervals[i]);
      if (time - history.times[last] > limit) {
        out.times.push((time + history.times[last]) / 2);
        out.cpu.push(null);
        out.ram.push(null);
        out.gpu.push(null);
      }
    }
    out.times.push(time);
    out.cpu.push(history.cpu[i]);
    out.ram.push(history.ram[i]);
    out.gpu.push(history.gpu[i]);
    last = i;
  });
  return out;
}

const round2 = (n) => Math.round(n * 100) / 100;

// A run of [x, y] points with at most one point per pixel column: of the points that share a column the highest
// value (the smallest y) stays, so peaks are kept. The first and the last point always stay as they are. An hour
// at 0.5 s is 7200 points, far more than a graph has pixels.
function thinRun(run) {
  if (run.length <= 2) return run;
  const out = [run[0]];
  let column = null;
  let best = null;
  for (let i = 1; i < run.length - 1; i++) {
    const point = run[i];
    const x = Math.floor(point[0]);
    if (x !== column) {
      if (best !== null) out.push(best);
      column = x;
      best = point;
    } else if (point[1] < best[1]) {
      best = point;
    }
  }
  out.push(best);
  out.push(run[run.length - 1]);
  return out;
}

// SVG path strings for a graph of `view.width` x `view.height` showing the last `view.minutes` minutes before `view.now` on a fixed
// 0-100 axis: `line` (one open sub-path per run of values) and `fill` (the same runs closed down to the bottom).
// Each run is thinned to about one point per pixel of the width (see thinRun).
export function graphPaths(times, values, view) {
  const { minutes, now, width, height } = view;
  const span = minutes * 60_000;
  const runs = [];
  let run = null;
  times.forEach((time, i) => {
    const value = values[i];
    const x = ((time - (now - span)) / span) * width;
    if (value === null || value === undefined || x < 0 || x > width) {
      run = null;
      return;
    }
    if (run === null) {
      run = [];
      runs.push(run);
    }
    run.push([round2(x), round2(height - (Math.min(100, Math.max(0, value)) / 100) * height)]);
  });
  const open = (r) =>
    `M ${r[0][0]} ${r[0][1]}` +
    r
      .slice(1)
      .map(([x, y]) => ` L ${x} ${y}`)
      .join("");
  // A lone point becomes a dot (a zero-length line).
  const dot = (r) => (r.length === 1 ? `${open(r)} L ${r[0][0]} ${r[0][1]}` : open(r));
  const closed = (r) => `${open(r)} L ${r[r.length - 1][0]} ${height} L ${r[0][0]} ${height} Z`;
  const thinned = runs.map(thinRun);
  return {
    line: thinned.map(dot).join(" "),
    fill: thinned
      .filter((r) => r.length > 1)
      .map(closed)
      .join(" "),
  };
}
