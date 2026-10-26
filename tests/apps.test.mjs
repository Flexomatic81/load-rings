// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import { USAGE_NORMALIZED, cpuShare, readRow, topConsumers } from "../package/contents/code/apps.mjs";

const MiB = 1024 * 1024;
const GiB = 1024 * MiB;

const rows = [
  { name: "Firefox", icon: "firefox", kind: "app", pids: Array(12).fill(1), cpu: 14.2, memory: 4.1 * GiB },
  { name: "baloo_file", icon: "", kind: "service", pids: [1], cpu: 2.8, memory: 90 * MiB },
  { name: "Idle", icon: "", kind: "app", pids: [1], cpu: 0, memory: 0 },
];

test("cpu ranking with shares of the whole cpu", () => {
  const top = topConsumers(rows, "cpu", 100);
  assert.deepEqual(
    top.map((r) => [r.name, r.processCount, r.value]),
    [
      ["Firefox", 12, 14.2],
      ["baloo_file", 1, 2.8],
    ],
  );
  assert.equal(top[0].share, 0.142);
  assert.deepEqual(top[0], {
    name: "Firefox",
    icon: "firefox",
    kind: "app",
    processCount: 12,
    value: 14.2,
    share: 0.142,
  });
  assert.equal(top[1].kind, "service");
});

test("memory ranking against total memory", () => {
  const top = topConsumers(rows, "memory", 32 * GiB);
  assert.equal(top[0].share, 4.1 / 32);
  assert.deepEqual(
    top.map((r) => r.name),
    ["Firefox", "baloo_file"],
  );
});

test("limit", () => {
  const many = [];
  for (let i = 1; i <= 7; i++) many.push({ name: "p" + i, icon: "", kind: "app", pids: [i], cpu: i, memory: i });
  const top = topConsumers(many, "cpu", 100);
  assert.equal(top.length, 5);
  assert.deepEqual(
    top.map((r) => r.name),
    ["p7", "p6", "p5", "p4", "p3"],
  );
  assert.equal(topConsumers(many, "memory", 100, 2).length, 2);
});

test("ties are ordered by name", () => {
  const tied = [
    { name: "b", icon: "", kind: "app", pids: [1], cpu: 5, memory: 1 },
    { name: "a", icon: "", kind: "app", pids: [2], cpu: 5, memory: 1 },
    { name: "a", icon: "", kind: "app", pids: [3], cpu: 5, memory: 1 },
  ];
  assert.deepEqual(
    topConsumers(tied, "cpu", 100).map((r) => r.name),
    ["a", "a", "b"],
  );
});

test("missing, zero and negative values and rows without processes are left out", () => {
  const odd = [
    { name: "null", icon: "", kind: "app", pids: [1], cpu: null, memory: null },
    { name: "nan", icon: "", kind: "app", pids: [1], cpu: NaN, memory: undefined },
    { name: "neg", icon: "", kind: "app", pids: [1], cpu: -1, memory: -1 },
    { name: "gone", icon: "", kind: "app", pids: [], cpu: 50, memory: 50 },
    { name: "nopids", icon: "", kind: "app", cpu: 40, memory: 40 },
    { name: "ok", icon: "", kind: "app", pids: [1, 2], cpu: 1, memory: 1 },
  ];
  assert.deepEqual(
    topConsumers(odd, "cpu", 100).map((r) => r.name),
    ["ok"],
  );
  assert.deepEqual(
    topConsumers(odd, "memory", 100).map((r) => r.name),
    ["ok"],
  );
  assert.deepEqual(topConsumers(null, "cpu", 100), []);
  assert.deepEqual(topConsumers([], "cpu", 100), []);
});

test("shares are clamped and need a total", () => {
  const one = [{ name: "x", icon: "", kind: "app", pids: [1], cpu: 150, memory: 5 }];
  assert.equal(topConsumers(one, "cpu", 100)[0].share, 1);
  for (const total of [0, -1, NaN, null, undefined]) {
    const top = topConsumers(one, "cpu", total);
    assert.equal(top.length, 1);
    assert.equal(top[0].share, null);
  }
});

test("cpu share", () => {
  assert.equal(cpuShare(100, 16, false), 6.25);
  assert.equal(cpuShare(14, 16, true), 14);
  assert.equal(cpuShare(14, NaN, true), 14);
  for (const cores of [NaN, 0, -2, null, undefined]) assert.equal(cpuShare(100, cores, false), null);
  for (const usage of [NaN, null, undefined, "5"]) assert.equal(cpuShare(usage, 16, false), null);
});

test("the usage of the process model counts per core", () => {
  // Measured: one busy process reads about 100, not 100 / cores.
  assert.equal(USAGE_NORMALIZED, false);
});

test("a model row becomes a ranking row", () => {
  assert.deepEqual(
    readRow(
      { name: "Firefox", icon: "firefox", menuId: "firefox.desktop", usage: 160, memoryKiB: 2048, pids: [3, 4] },
      16,
    ),
    {
      name: "Firefox",
      icon: "firefox",
      kind: "app",
      pids: [3, 4],
      cpu: USAGE_NORMALIZED ? 160 : 10,
      memory: 2048 * 1024,
    },
  );
  const services = readRow(
    {
      name: "Background services",
      icon: "preferences-system-services",
      menuId: "services",
      usage: 0,
      memoryKiB: 10,
      pids: [1],
    },
    16,
  );
  assert.equal(services.kind, "service");
  assert.equal(services.name, "Background services");
});

test("a model row with missing data", () => {
  assert.deepEqual(readRow({}, NaN), {
    name: "",
    icon: "",
    kind: "app",
    pids: [],
    cpu: null,
    memory: null,
  });
  assert.deepEqual(readRow({ name: 5, icon: null, usage: 3, memoryKiB: NaN, pids: "x" }, 0), {
    name: "5",
    icon: "",
    kind: "app",
    pids: [],
    cpu: null,
    memory: null,
  });
});

test("a row list-like pids value from the model is copied into an array", () => {
  // The model hands over a QVariantList, which QML exposes as an array-like object.
  const listLike = { length: 2, 0: 7, 1: 8 };
  assert.deepEqual(readRow({ name: "x", pids: listLike }, 4).pids, [7, 8]);
});

test("a model row with null fields", () => {
  const row = readRow({ name: null, pids: null, usage: 8, memoryKiB: 1 }, 8);
  assert.equal(row.name, "");
  assert.deepEqual(row.pids, []);
  assert.equal(row.memory, 1024);
});

test("ties are ordered by name in either input order", () => {
  const a = { name: "a", icon: "", kind: "app", pids: [1], cpu: 5, memory: 1 };
  const b = { name: "b", icon: "", kind: "app", pids: [1], cpu: 5, memory: 1 };
  assert.deepEqual(
    topConsumers([a, b], "cpu", 100).map((r) => r.name),
    ["a", "b"],
  );
  assert.deepEqual(
    topConsumers([b, a], "cpu", 100).map((r) => r.name),
    ["a", "b"],
  );
});
