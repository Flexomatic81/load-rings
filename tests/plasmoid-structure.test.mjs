// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Structural checks for Plasma requirements that no qml6/plasmawindowed run
// can exercise.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const mainQml = readFileSync(new URL("../package/contents/ui/main.qml", import.meta.url), "utf8");

// Plasma 6 never instantiates the compactRepresentation of a PlasmoidItem
// that has no fullRepresentation: the panel then shows an empty 42x42 box
// (observed 2026-10-24 on Plasma 6.7.5).
test("main.qml declares a fullRepresentation so Plasma creates the compact view", () => {
  assert.match(mainQml, /^\s*fullRepresentation\s*:/m);
});

// Picking a time window in the popup assigns graphMinutes and so ends its binding to the setting; a later change
// of "Graph shows by default" must still reach the popup without a restart.
test("main.qml applies a changed default time window after a window was picked", () => {
  assert.match(
    mainQml,
    /readonly property int defaultMinutes: HistoryCode\.validMinutes\(Plasmoid\.configuration\.historyMinutes\)/,
  );
  assert.match(mainQml, /property int graphMinutes: root\.defaultMinutes/);
  assert.match(mainQml, /onDefaultMinutesChanged: root\.graphMinutes = root\.defaultMinutes/);
});
