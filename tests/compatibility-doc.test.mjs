// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Keeps docs/compatibility.md in step with the package: every QML module the applet imports and every sensor it
// reads must be listed there, and the stated minimum must match metadata.json and the README.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";

const contentsDir = new URL("../package/contents/", import.meta.url);
const docUrl = new URL("../docs/compatibility.md", import.meta.url);
const metadata = JSON.parse(readFileSync(new URL("../package/metadata.json", import.meta.url), "utf8"));

function packageFiles(suffix) {
  return readdirSync(contentsDir, { recursive: true })
    .map(String)
    .filter((f) => f.endsWith(suffix))
    .map((f) => readFileSync(new URL(f, contentsDir), "utf8"));
}

// Module names from `import Some.Module` lines; relative imports ("...") are files of the package itself.
function importedModules() {
  const modules = new Set();
  for (const text of packageFiles(".qml")) {
    for (const match of text.matchAll(/^import\s+([A-Za-z][\w.]*)/gm)) modules.add(match[1]);
  }
  return [...modules].sort();
}

// The fixed sensor IDs ("cpu/all/usage", "os/system/uptime") in the QML and the code modules.
function sensorIds() {
  const ids = new Set();
  for (const text of [...packageFiles(".qml"), ...packageFiles(".mjs")]) {
    for (const match of text.matchAll(/"((?:cpu|memory|os)\/[a-z]+\/[A-Za-z]+)"/g)) ids.add(match[1]);
  }
  return [...ids].sort();
}

// The document with every run of white space as one space, so that line wrapping does not matter.
function readDoc() {
  return readFileSync(docUrl, "utf8").replace(/\s+/g, " ");
}

test("the package imports QML modules and reads sensors at all", () => {
  assert.ok(importedModules().includes("org.kde.plasma.plasmoid"));
  assert.ok(sensorIds().includes("cpu/all/usage"));
});

test("docs/compatibility.md lists every imported QML module", () => {
  const doc = readDoc();
  assert.deepEqual(
    importedModules().filter((name) => !doc.includes("`" + name + "`")),
    [],
  );
});

test("docs/compatibility.md lists every fixed sensor ID", () => {
  const doc = readDoc();
  assert.deepEqual(
    sensorIds().filter((id) => !doc.includes("`" + id + "`")),
    [],
  );
});

test("docs/compatibility.md states the supported minimum while the metadata keeps API 6.0", () => {
  const doc = readDoc();
  assert.equal(metadata["X-Plasma-API-Minimum-Version"], "6.0");
  assert.match(doc, /Plasma 6\.3 or newer/);
  assert.match(doc, /KDE Frameworks 6\.10 or newer/);
  assert.match(doc, /Qt 6\.7 or newer/);
});
