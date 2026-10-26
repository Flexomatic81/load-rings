// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import {
  HEARTBEAT_SENSOR,
  heartbeatWindowMs,
  isHeartbeatFresh,
  initialHeartbeatGate,
  heartbeatGate,
  heartbeatAllows,
  coreSensorIds,
  gpuIdsFromSensorIds,
  gpuSensorIds,
  pickGpu,
  cleanValue,
  maxFinite,
  blankNumbers,
  tickSample,
  ringValues,
} from "../package/contents/code/sensors.mjs";

test("heartbeat sensor", () => {
  assert.equal(HEARTBEAT_SENSOR, "os/system/uptime");
});

test("heartbeat window", () => {
  assert.equal(heartbeatWindowMs(500), 3000);
  assert.equal(heartbeatWindowMs(2000), 6000);
  assert.equal(isHeartbeatFresh(10000, 13000, 1000), true);
  assert.equal(isHeartbeatFresh(10000, 13001, 1000), false);
});
// Feeds heartbeat values to the gate: pairs of [now, value].
function beats(state, pairs) {
  let gate = state;
  for (const [now, value] of pairs) gate = heartbeatGate(gate, { type: "heartbeat", now: now, value: value });
  return gate;
}
test("heartbeat gate starts out requiring a heartbeat", () => {
  const gate = initialHeartbeatGate();
  assert.deepEqual(gate, { required: true, lastHeartbeatAt: 0, hasValue: false, lastValue: undefined });
  assert.equal(heartbeatAllows(gate, 1700000000000, 1000), false);
});
test("heartbeat gate does not arm on a single value, so the probe still switches it off", () => {
  const one = beats(initialHeartbeatGate(), [[2000, 0]]);
  assert.equal(one.lastHeartbeatAt, 0);
  const off = heartbeatGate(one, { type: "probe-expired", sensorReady: false });
  assert.equal(off.required, false);
  assert.equal(heartbeatAllows(off, 99999, 1000), true);
});
test("heartbeat gate does not arm on the same value repeated", () => {
  const same = beats(initialHeartbeatGate(), [
    [2000, 7],
    [3000, 7],
    [4000, 7],
  ]);
  assert.equal(same.lastHeartbeatAt, 0);
  assert.equal(heartbeatGate(same, { type: "heartbeat", now: 5000, value: 7 }), same);
  assert.equal(heartbeatGate(same, { type: "probe-expired", sensorReady: false }).required, false);
});
test("heartbeat gate treats a repeated NaN as the same value", () => {
  const nan = beats(initialHeartbeatGate(), [
    [2000, NaN],
    [3000, NaN],
  ]);
  assert.equal(nan.lastHeartbeatAt, 0);
});
test("heartbeat gate arms once the value changes, and records each change", () => {
  const gate = beats(initialHeartbeatGate(), [
    [4000, 10],
    [5000, 11],
  ]);
  assert.deepEqual(gate, { required: true, lastHeartbeatAt: 5000, hasValue: true, lastValue: 11 });
  assert.equal(heartbeatAllows(gate, 8000, 1000), true);
  assert.equal(heartbeatAllows(gate, 8001, 1000), false);
  // A repeat of the last value is no sign of life.
  assert.equal(beats(gate, [[6000, 11]]), gate);
});
test("heartbeat gate switches off when the probe finds no heartbeat sensor", () => {
  const gate = heartbeatGate(initialHeartbeatGate(), { type: "probe-expired", sensorReady: false });
  assert.equal(gate.required, false);
  assert.equal(gate.lastHeartbeatAt, 0);
  assert.equal(heartbeatAllows(gate, 99999, 1000), true);
});
test("heartbeat gate stays on when the probe finds the sensor", () => {
  const start = initialHeartbeatGate();
  assert.equal(heartbeatGate(start, { type: "probe-expired", sensorReady: true }), start);
});
test("heartbeat gate stays on after the probe once the heartbeat changed", () => {
  const seen = beats(initialHeartbeatGate(), [
    [1000, 1],
    [2000, 2],
  ]);
  assert.equal(heartbeatGate(seen, { type: "probe-expired", sensorReady: false }), seen);
  assert.equal(heartbeatAllows(seen, 20000, 1000), false);
});
test("heartbeat gate switches back on with a late heartbeat", () => {
  const off = heartbeatGate(initialHeartbeatGate(), { type: "probe-expired", sensorReady: false });
  const first = beats(off, [[29000, 100]]);
  assert.equal(first.required, false);
  const late = beats(first, [[30000, 101]]);
  assert.deepEqual(late, { required: true, lastHeartbeatAt: 30000, hasValue: true, lastValue: 101 });
  assert.equal(heartbeatAllows(late, 33000, 1000), true);
  // The heartbeat stops again: samples are held back after the window.
  assert.equal(heartbeatAllows(late, 33001, 1000), false);
  // It comes back: samples pass again.
  const back = beats(late, [[40000, 111]]);
  assert.equal(heartbeatAllows(back, 40500, 1000), true);
});
test("heartbeat gate ignores unknown events", () => {
  const start = initialHeartbeatGate();
  assert.equal(heartbeatGate(start, { type: "other" }), start);
});

test("core sensor ids", () => {
  assert.deepEqual(coreSensorIds(3), {
    usage: "cpu/cpu3/usage",
    frequency: "cpu/cpu3/frequency",
    temperature: "cpu/cpu3/temperature",
  });
});
test("gpu ids", () => {
  assert.deepEqual(
    gpuIdsFromSensorIds([
      "gpu/gpu1/usage",
      "gpu/all/usage",
      "gpu/gpu0/usage",
      "gpu/gpu10/usage",
      "gpu/gpu0/temperature",
    ]),
    ["gpu0", "gpu1", "gpu10"],
  );
  assert.deepEqual(gpuIdsFromSensorIds(["cpu/cpu0/usage", "gpu/gpu2", 5, "gpu/gpuX/usage"]), []);
});
test("gpu sensor ids", () => {
  assert.deepEqual(gpuSensorIds("gpu0"), {
    name: "gpu/gpu0/name",
    usage: "gpu/gpu0/usage",
    temperature: "gpu/gpu0/temperature",
    temp2: "gpu/gpu0/temp2",
    temp3: "gpu/gpu0/temp3",
    coreFrequency: "gpu/gpu0/coreFrequency",
    memoryFrequency: "gpu/gpu0/memoryFrequency",
    usedVram: "gpu/gpu0/usedVram",
    totalVram: "gpu/gpu0/totalVram",
    power: "gpu/gpu0/power",
    fan1: "gpu/gpu0/fan1",
  });
});
test("pick gpu", () => {
  assert.equal(pickGpu(["gpu0", "gpu1"], "gpu1"), "gpu1");
  assert.equal(pickGpu(["gpu0"], "gpu3"), "gpu0");
  assert.equal(pickGpu(["gpu0", "gpu1"], ""), "gpu0");
  assert.equal(pickGpu([], ""), null);
});
test("clean values", () => {
  assert.equal(cleanValue(3), 3);
  assert.equal(cleanValue(0), 0);
  assert.equal(cleanValue(-2.5), -2.5);
  for (const v of [undefined, null, NaN, "", "12", Infinity]) assert.equal(cleanValue(v), null);
});

test("maxFinite", () => {
  assert.equal(maxFinite([40, NaN, 55, undefined, 50]), 55);
  assert.equal(maxFinite([-3, -1]), -1);
  assert.equal(maxFinite([NaN]), NaN);
  assert.equal(maxFinite([]), NaN);
});
test("blankNumbers keeps shape and text, blanks numbers", () => {
  const blank = blankNumbers({
    a: 1,
    name: "x",
    flag: true,
    list: [{ u: 2 }, { u: 3 }],
    gpu: { n: "g", v: 4 },
    none: null,
  });
  assert.equal(blank.a, NaN);
  assert.equal(blank.name, "x");
  assert.equal(blank.flag, true);
  assert.equal(blank.list.length, 2);
  assert.equal(blank.list[1].u, NaN);
  assert.equal(blank.gpu.n, "g");
  assert.equal(blank.gpu.v, NaN);
  assert.equal(blank.none, null);
});
test("tickSample", () => {
  const current = { cpuUsage: 12.5, memUsedPercent: 40, cpuTemperature: NaN, gpu: { usage: 7, temperature: 61 } };
  assert.deepEqual(tickSample(1000, 2000, current, "gpu0"), {
    timestamp: 1000,
    intervalMs: 2000,
    cpu: 12.5,
    ram: 40,
    gpu: 7,
    gpuId: "gpu0",
    cpuTemp: null,
    gpuTemp: 61,
  });
  const off = tickSample(1, 500, current, null);
  assert.equal(off.gpu, null);
  assert.equal(off.gpuTemp, null);
  assert.equal(off.gpuId, null);
});

test("ringValues", () => {
  const current = { cpuUsage: 34, memUsedPercent: NaN, gpu: { usage: 7 } };
  assert.deepEqual(ringValues(current, false), [
    { key: "cpu", percent: 34 },
    { key: "ram", percent: NaN },
  ]);
  assert.deepEqual(
    ringValues(current, true).map((r) => r.key + ":" + r.percent),
    ["cpu:34", "ram:NaN", "gpu:7"],
  );
});
