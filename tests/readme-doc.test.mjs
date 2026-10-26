// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Keeps README.md and docs/store.md in step with the package: the settings table quotes only options of the
// settings page and names all of them, the interval range is the one of main.xml, the screenshots are the ones the
// screenshot tool writes, the store images exist, and the store's short descriptions fit the form.
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { SHOTS } from "../tools/screenshots/demo.mjs";

const readme = readFileSync(new URL("../README.md", import.meta.url), "utf8");
const store = readFileSync(new URL("../docs/store.md", import.meta.url), "utf8");
const configDir = new URL("../package/contents/ui/config/", import.meta.url);

// The text of a "## " section up to the next one; "" when it is missing.
function section(text, heading) {
  const start = text.indexOf("\n## " + heading + "\n");
  if (start < 0) return "";
  const end = text.indexOf("\n## ", start + 1);
  return text.slice(start, end < 0 ? text.length : end);
}

// The labels of the settings page: every text it passes to tr() or trc() that ends with a colon or names a switch.
function configTexts() {
  const texts = new Set();
  for (const file of readdirSync(configDir).filter((f) => f.endsWith(".qml"))) {
    const qml = readFileSync(new URL(file, configDir), "utf8");
    for (const match of qml.matchAll(/\btr\("([^"]+)"|\btrc\("[^"]*",\s*"([^"]+)"/g)) {
      texts.add(match[1] ?? match[2]);
    }
  }
  return texts;
}

// The value of an entry in main.xml, or of one of its limits.
function configEntry(name, tag) {
  const xml = readFileSync(new URL("../package/contents/config/main.xml", import.meta.url), "utf8");
  const entry = xml.match(new RegExp('<entry name="' + name + '"[^>]*>([\\s\\S]*?)</entry>'));
  assert.ok(entry, name);
  const value = entry[1].match(new RegExp("<" + tag + ">([^<]*)</" + tag + ">"));
  return value ? value[1] : null;
}

test("the settings table quotes only options of the settings page, and every one of them", () => {
  const rows = section(readme, "Settings")
    .split("\n")
    .filter((line) => line.startsWith("| "));
  const quoted = rows.flatMap((row) => [...row.matchAll(/"([^"]+)"/g)].map((m) => m[1]));
  const known = configTexts();
  assert.deepEqual(
    quoted.filter((text) => !known.has(text)),
    [],
  );
  for (const label of ["Update interval:", "Graph shows by default:", "Show graphics card", "Graphics card:"]) {
    assert.ok(known.has(label), label + " on the settings page");
    assert.ok(quoted.includes(label), label + " in the README");
  }
});

test("the settings table states the ranges and defaults of main.xml", () => {
  const table = section(readme, "Settings").replace(/\s+/g, " ");
  assert.match(table, /0\.5 to 10 seconds, default 2/);
  assert.equal(configEntry("updateInterval", "min"), "0.5");
  assert.equal(configEntry("updateInterval", "max"), "10");
  assert.equal(configEntry("updateInterval", "default"), "2.0");
  assert.match(table, /default 5 minutes/);
  assert.equal(configEntry("historyMinutes", "default"), "5");
  assert.match(table, /off by default/);
  assert.equal(configEntry("showGpu", "default"), "false");
});

test("the README states the supported minimum", () => {
  const text = readme.replace(/\s+/g, " ");
  assert.match(text, /Plasma 6\.3 or newer, with KDE Frameworks 6\.10 and Qt 6\.7 or newer/);
});

test("the README and the store text list every screenshot", () => {
  for (const name of SHOTS) {
    assert.ok(readme.includes("docs/images/" + name), name + " in README.md");
    assert.ok(store.includes("`" + name + "`"), name + " in docs/store.md");
    assert.ok(existsSync(new URL("../docs/images/" + name, import.meta.url)), name + " in docs/images");
    assert.ok(existsSync(new URL("../docs/images/light/" + name, import.meta.url)), name + " in docs/images/light");
    assert.ok(existsSync(new URL("../docs/store/shots/" + name, import.meta.url)), name + " in docs/store/shots");
  }
});

test("the store images the store text names exist", () => {
  const names = [...store.matchAll(/`(store-\d-[a-z-]+\.png)`/g)].map((m) => m[1]);
  assert.ok(names.length >= 4 && names.length <= 5, "between four and five images");
  for (const name of names) {
    assert.ok(existsSync(new URL("../docs/store/" + name, import.meta.url)), name);
    assert.ok(readme.includes("docs/store/" + name), name + " in README.md");
  }
  assert.ok(existsSync(new URL("../docs/store/loadrings-store.vectorcraft", import.meta.url)));
});

test("the store's short descriptions fit in 200 characters", () => {
  const lines = section(store, "Short description")
    .split("\n")
    .filter((line) => line.startsWith("> "));
  assert.equal(lines.length, 2);
  for (const line of lines) {
    assert.ok([...line.slice(2)].length <= 200, line);
  }
});
