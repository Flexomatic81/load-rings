// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { STATS_COMMAND, parseStats, ctxtRate } from "../package/contents/code/procstats.mjs";

const read = (name) => fs.readFileSync(new URL(`./fixtures/${name}`, import.meta.url), "utf8");

test("full output", () => {
  const s = parseStats(read("stats-full.txt"));
  assert.deepEqual(s.loadavg, [2.1, 1.8, 1.4]);
  assert.equal(s.ctxt, 123456789);
  assert.equal(s.psiCpu, 3);
  assert.equal(s.psiMemory, 0.4);
  assert.equal(s.memFree, 1048576 * 1024);
  assert.equal(s.shmem, 524288 * 1024);
  assert.equal(s.governor, "schedutil");
  assert.equal(s.epp, "balance_performance");
  assert.deepEqual(s.zram[0], { name: "zram0", orig: 2040109465, compr: 637534208, used: 671088640 });
});

test("missing sections are null", () => {
  const s = parseStats(read("stats-minimal.txt"));
  assert.deepEqual(s.loadavg, [0.5, 0.4, 0.3]);
  assert.equal(s.ctxt, 5000);
  assert.equal(s.psiCpu, null);
  assert.equal(s.psiMemory, null);
  assert.deepEqual(s.zram, []);
  assert.equal(s.governor, null);
  assert.equal(s.epp, null);
  assert.equal(s.memFree, null);
  assert.equal(s.shmem, null);
});

test("empty and garbled input gives nulls", () => {
  for (const input of ["", "garbage\n@@loadavg\nx y z\n@@stat\nctxt abc\n@@zram\nzram0 1 2\n"]) {
    const s = parseStats(input);
    assert.equal(s.loadavg, null);
    assert.equal(s.ctxt, null);
    assert.deepEqual(s.zram, []);
  }
});

test("several zram devices", () => {
  const s = parseStats("@@zram\nzram0 10 5 6 0\nzram1 20 8 9 0\n");
  assert.deepEqual(
    s.zram.map((z) => z.name),
    ["zram0", "zram1"],
  );
});

test("context switch rate", () => {
  assert.equal(ctxtRate({ timestamp: 0, ctxt: 1000 }, { timestamp: 2000, ctxt: 83000 }), 41000);
  assert.equal(ctxtRate(null, { timestamp: 0, ctxt: 5 }), null);
  assert.equal(ctxtRate({ timestamp: 0, ctxt: 9000 }, { timestamp: 2000, ctxt: 10 }), null);
  assert.equal(ctxtRate({ timestamp: 0, ctxt: 1 }, { timestamp: 60000, ctxt: 9 }), null);
  assert.equal(ctxtRate({ timestamp: 5, ctxt: 1 }, { timestamp: 5, ctxt: 9 }), null);
});

test("the command names every section and hides read errors", () => {
  for (const name of ["loadavg", "stat", "psi_cpu", "psi_memory", "meminfo", "zram", "governor", "epp"]) {
    assert.ok(STATS_COMMAND.includes(`@@${name}`), name);
  }
  assert.ok(STATS_COMMAND.includes("2>/dev/null"));
});
