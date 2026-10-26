// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Helpers for the ksystemstats source. Pure functions without Qt or
// Plasma dependencies, so the module runs inside QML as well as under Node.

// Changes about once a second. libksysguard does not re-emit unchanged values,
// so network values alone cannot tell "idle" from "stopped"; the system
// uptime can.
export const HEARTBEAT_SENSOR = "os/system/uptime";

const MIN_HEARTBEAT_WINDOW_MS = 3000;
const HEARTBEAT_WINDOW_FACTOR = 3;

// How old the last heartbeat may be before the sensors count as stalled.
export function heartbeatWindowMs(intervalMs) {
  return Math.max(HEARTBEAT_WINDOW_FACTOR * intervalMs, MIN_HEARTBEAT_WINDOW_MS);
}

export function isHeartbeatFresh(lastHeartbeatAt, now, intervalMs) {
  return now - lastHeartbeatAt <= heartbeatWindowMs(intervalMs);
}

// State of the heartbeat check: whether samples need a fresh heartbeat, the
// time of the last heartbeat (0 before the first), and the last value the
// heartbeat sensor reported. Samples wait for the first heartbeat.
export function initialHeartbeatGate() {
  return { required: true, lastHeartbeatAt: 0, hasValue: false, lastValue: undefined };
}

function copyGate(state, changes) {
  const next = {
    required: state.required,
    lastHeartbeatAt: state.lastHeartbeatAt,
    hasValue: state.hasValue,
    lastValue: state.lastValue,
  };
  for (const key of Object.keys(changes)) next[key] = changes[key];
  return next;
}

// Next state of the heartbeat check. Events:
//   { type: "heartbeat", now, value }        the heartbeat sensor reported a value
//   { type: "probe-expired", sensorReady }   the start-up probe is over
// Only a change of the value is a heartbeat: the first value, or the same one
// again, may be a placeholder of a sensor that does not work. A heartbeat
// switches the check on, also again after the probe switched it off, so a
// service that starts late, or stops after that, is noticed. The probe
// switches the check off only when the sensor is missing and no heartbeat has
// come so far (a Plasma version without it). Returns the same object when
// nothing changes.
export function heartbeatGate(state, event) {
  if (event.type === "heartbeat") {
    if (!state.hasValue) return copyGate(state, { hasValue: true, lastValue: event.value });
    if (Object.is(event.value, state.lastValue)) return state;
    return copyGate(state, { required: true, lastHeartbeatAt: event.now, lastValue: event.value });
  }
  if (event.type === "probe-expired" && !event.sensorReady && state.lastHeartbeatAt === 0) {
    return copyGate(state, { required: false });
  }
  return state;
}

// True when a sample taken at `now` may be passed on.
export function heartbeatAllows(state, now, intervalMs) {
  return !state.required || isHeartbeatFresh(state.lastHeartbeatAt, now, intervalMs);
}

// Sensor IDs of one CPU thread, "cpu/cpu<index>/...".
export function coreSensorIds(index) {
  const base = "cpu/cpu" + index + "/";
  return { usage: base + "usage", frequency: base + "frequency", temperature: base + "temperature" };
}

const GPU_SENSOR = /^gpu\/(gpu(\d+))\/[^/]+$/;

// Unique GPU names ("gpu0", "gpu1", ...) from the sensor IDs, sorted by number.
// The "gpu/all/..." aggregate is not a GPU.
export function gpuIdsFromSensorIds(ids) {
  const found = new Map();
  for (const id of ids) {
    const match = typeof id === "string" ? GPU_SENSOR.exec(id) : null;
    if (match) found.set(match[1], Number(match[2]));
  }
  return Array.from(found.keys()).sort((a, b) => found.get(a) - found.get(b));
}

const GPU_FIELDS = [
  "name",
  "usage",
  "temperature",
  "temp2",
  "temp3",
  "coreFrequency",
  "memoryFrequency",
  "usedVram",
  "totalVram",
  "power",
  "fan1",
];

// Sensor IDs of one GPU, by the last part of the ID.
export function gpuSensorIds(gpuId) {
  const base = "gpu/" + gpuId + "/";
  const ids = {};
  for (const field of GPU_FIELDS) ids[field] = base + field;
  return ids;
}

// The wanted GPU if it exists, else the first one, else null.
export function pickGpu(available, wanted) {
  if (available.indexOf(wanted) >= 0) return wanted;
  return available.length > 0 ? available[0] : null;
}

// A finite number as it is, anything else (not yet read, text, NaN) null.
export function cleanValue(value) {
  return typeof value === "number" && isFinite(value) ? value : null;
}
