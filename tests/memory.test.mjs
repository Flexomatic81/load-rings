// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import { memoryBreakdown, zramRatio } from "../package/contents/code/memory.mjs";

const sum = (segments) => segments.reduce((a, x) => a + x.bytes, 0);

test("segments add up to the total", () => {
  const s = memoryBreakdown({
    total: 33542184960,
    used: 6169120768,
    application: 5329989632,
    memFree: 8684703744,
  });
  assert.deepEqual(
    s.map((x) => x.key),
    ["apps", "other", "cache", "free"],
  );
  assert.equal(sum(s), 33542184960);
  assert.equal(s[0].bytes, 5329989632);
  assert.equal(s[1].bytes, 6169120768 - 5329989632);
  assert.equal(s[3].bytes, 8684703744);
});

test("without MemFree the rest is available", () => {
  for (const memFree of [null, undefined]) {
    const s = memoryBreakdown({ total: 1000, used: 400, application: 300, memFree });
    assert.deepEqual(s, [
      { key: "apps", bytes: 300 },
      { key: "other", bytes: 100 },
      { key: "available", bytes: 600 },
    ]);
  }
});

test("inconsistent sensors never go negative", () => {
  // application larger than used
  let s = memoryBreakdown({ total: 1000, used: 400, application: 500, memFree: 300 });
  assert.ok(s.every((x) => x.bytes >= 0));
  assert.equal(sum(s), 1000);
  assert.equal(s[1].bytes, 0);
  // MemFree larger than what is left over: the cache cannot be negative
  s = memoryBreakdown({ total: 1000, used: 400, application: 300, memFree: 700 });
  assert.ok(s.every((x) => x.bytes >= 0));
  assert.equal(sum(s), 1000);
  assert.equal(s[2].bytes, 0);
  // used larger than total: nothing exceeds the total
  s = memoryBreakdown({ total: 1000, used: 1500, application: 1200, memFree: 0 });
  assert.ok(s.every((x) => x.bytes >= 0));
  assert.equal(sum(s), 1000);
  s = memoryBreakdown({ total: 1000, used: 1500, application: 1200, memFree: null });
  assert.ok(s.every((x) => x.bytes >= 0));
  assert.equal(sum(s), 1000);
});

test("a missing application value counts as zero", () => {
  const s = memoryBreakdown({ total: 1000, used: 400, application: null, memFree: null });
  assert.deepEqual(
    s.map((x) => x.bytes),
    [0, 400, 600],
  );
});

test("without total or used there are no segments", () => {
  assert.deepEqual(memoryBreakdown({ total: null, used: 1, application: 1, memFree: 1 }), []);
  assert.deepEqual(memoryBreakdown({ total: 1000, used: null, application: 1, memFree: 1 }), []);
  assert.deepEqual(memoryBreakdown({ total: 0, used: 0, application: 0, memFree: 0 }), []);
  assert.deepEqual(memoryBreakdown({}), []);
});

test("zram ratio", () => {
  assert.equal(zramRatio({ orig: 2040109465, compr: 637534208 }), 3.2);
  assert.equal(zramRatio({ orig: 1, compr: 0 }), null);
  assert.equal(zramRatio({ orig: 1, compr: -5 }), null);
  assert.equal(zramRatio({ orig: 1, compr: null }), null);
  assert.equal(zramRatio({ orig: null, compr: 5 }), null);
});
