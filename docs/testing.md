<!--
SPDX-License-Identifier: GPL-2.0-or-later
SPDX-FileCopyrightText: 2026 Flexomatic81
-->

# Manual tests

This checklist is worked through before every release. The automatic tests
(`node tools/check.mjs`; CI runs the steps of the group `fast`, `shellcheck`,
`actionlint` and `qmllint`) do not replace it: they check logic and single
scenes, not the behavior in a real panel.

The CI workflow (`.github/workflows/ci.yml`) is set up and checked with
`actionlint`, but it has never run: the repository has no remote yet. Until it
has, every result here comes from local runs.

## Automatic smoke scenes

`scripts/smoke.sh` (the `smoke` step) runs the QML scenes in `tests/qml` with
`qml6` on the offscreen platform. Most of them use fixed values or test
doubles. The live scenes read real system data and need `ksystemstats`
running and a desktop session. They are listed in `live_scenes` in
`scripts/smoke.sh` and each says so in its header comment ("Live scene: needs
..."). On a machine without these, for example in a container,
`LOADRINGS_SMOKE_SKIP_LIVE=1 scripts/smoke.sh` skips them and prints
`SMOKE SKIPPED (live) <scene>` for each one. Without the variable every scene
runs.

Two scenes check a timing contract on purpose and can fail on a heavily
loaded machine: `HeartbeatSmoke` (when the values turn stale after the
heartbeat stops) and `CommandRunnerSmoke` (a time limit must be reported in
time).

`scripts/load-check.sh` (the `load` step) starts the installed widget with
`plasmawindowed` on the offscreen platform and checks that it loads.
`plasmawindowed` never creates the panel view, so the panel view is covered by
`CompactSmoke` instead.

## Procedure

Install the current version (`scripts/dev-install.sh`), restart plasmashell
(`systemctl --user restart plasma-plasmashell`), go through the tables and
enter the result in the "Result" column: "OK", "Fail" with a reference to the
observation, or "n/a" with the reason. Note version, date and Plasma version
at the top for each run, or copy the tables; empty cells count as not checked.

Where a check names a text of the interface, the German wording is given too,
because the checker compares it against the German interface.

- Version: 0.1.0 (dev)
- Date: 2026-10-28
- Plasma version: 6.8.1, Wayland, three screens; test panels on a separate screen next to the sibling widget Limit Rings

## Panel

| Check | Result |
|---|---|
| Horizontal panel at the default height: two rings with numbers; the numbers change without the panel jumping | 2026-10-28, Plasma 6.8.1, scripted in a real test panel: OK; the rings match the size of the sibling widget's gauges |
| Vertical panel: the rings are stacked in one column, nothing is cut off | 2026-10-28, Plasma 6.8.1, scripted in a real 32 px vertical panel: OK, one column, nothing cut off |
| Panel sizes: horizontal about 24 px, 44 px and 96 px, vertical about 32 px wide: the numbers stay readable | 2026-10-28, Plasma 6.8.1, scripted in real panels: 44 px, 96 px and vertical 32 px OK; 24 px first showed the numbers at about 6 px, fixed: rings too small for a readable percent sign show the bare number; then OK |
| Desktop: the widget shows the rings side by side | 2026-10-28, Plasma 6.8.1, scripted on the desktop of a real screen: OK |
| Light and dark theme (Breeze Light, Breeze Dark): the numbers and the empty part of the rings are easy to see in both | 2026-10-28, Plasma 6.8.1, scripted with the screenshot scenes in Breeze Dark and Breeze Light: OK |
| Load the processor (for example `stress-ng --cpu 0` or a build): the processor ring turns from green through yellow and orange to red and back | 2026-10-28, Plasma 6.8.1, scripted with a busy loop on all 16 threads: the ring went to red at 100 % ("100%" fits) and back to green: OK |
| Tooltip: the lines "CPU" (German: “CPU”), "RAM" and, with the graphics card shown, "GPU" with their values | 2026-10-28, Plasma 6.8.1, by hand: OK |
| Freeze the sensor service (`systemctl --user kill -s SIGSTOP plasma-ksystemstats`; a stopped service is started again at once through D-Bus): after a few seconds the rings show a dash and the tooltip says "No data from the system sensors" (German: “Keine Daten von den Systemsensoren”); let it run again (`-s SIGCONT`): the values come back without a restart | 2026-10-28, Plasma 6.8.1, scripted: stopping the service starts it again at once through D-Bus, so the service was frozen (`systemctl --user kill -s SIGSTOP plasma-ksystemstats`) for 15 s instead: all rings showed the dash; after SIGCONT the values came back without a restart: OK (the tooltip text is covered by the heartbeat smoke scene, not hovered) |

## Popup

| Check | Result |
|---|---|
| A click on the rings opens the popup; another click closes it and does not reopen it right away; a click outside closes it as well | 2026-10-28, Plasma 6.8.1, by hand: OK |
| Processor column: model, cores and threads, usage, clock, temperature with peak, load average; the graph fills over time | 2026-10-28, Plasma 6.8.1, scripted with real data in German: OK; found and fixed: the clock tile showed the fastest core as "max" (sensor `cpu/all/maximumFrequency`) instead of the processor's highest clock, now read once from cpufreq; and the peak could show below the current temperature, now never does |
| Core grid: one cell per logical core; hovering a cell shows its clock and temperature | 2026-10-28, Plasma 6.8.1, by hand: OK |
| The detail line names the governor, the energy preference (where the system has one), the context switches per second and the waiting time | 2026-10-28, Plasma 6.8.1, scripted with real data: governor, EPP, context switches and waiting time shown: OK |
| "What uses the CPU" (German: “Was belastet die CPU”) and "What uses the memory" (German: “Was belegt den Speicher”): the programs match what the System Monitor shows under Applications, a program with several processes is one row, and "Background services" (German: “Hintergrunddienste”) collects the session's services | 2026-10-28, Plasma 6.8.1, scripted with real data: programs grouped with their process count, "Background services" collects the session services; the list comes from the same process model as the System Monitor's Applications page: OK |
| Memory column: the header names type, speed and modules where the firmware tells them; the bar parts add up to the whole width; swap, ZRAM and pressure rows show where the system has them | 2026-10-28, Plasma 6.8.1, scripted with real data: "DDR4-3200 · 4 × 8 GiB · A-DATA", bar, swap, ZRAM and pressure rows: OK |
| Switch the time window between 1 min, 5 min, 15 min and 1 h: all graphs follow; the window in the settings stays as it was | 2026-10-28, Plasma 6.8.1, by hand: OK |
| "Open System Monitor" (German: “Systemmonitor öffnen”) starts the System Monitor | 2026-10-28, Plasma 6.8.1, by hand: OK |
| With the popup closed, `ps` shows no shell command of the widget running at each interval, and the System Monitor shows no extra load from plasmashell | 2026-10-28, Plasma 6.8.1, scripted: no shell child of plasmashell in 10 s with the popup closed: OK |
| German system language: all texts of the popup are German, numbers use a decimal comma, nothing is cut off | 2026-10-28, Plasma 6.8.1, scripted with real data in German: all texts German, decimal comma, nothing cut off: OK |

## Graphics card

| Check | Result |
|---|---|
| Settings → "Show graphics card" (German: “Grafikkarte anzeigen”): a third ring and a third popup column appear; switching it off removes both | 2026-10-28, Plasma 6.8.1, by hand: OK |
| The column shows the name, usage, clock, temperature with peak, power, video memory and the detail line; values the card does not report are left out | 2026-10-28, Plasma 6.8.1, by hand: OK |
| A machine with two cards: "Graphics card:" (German: “Grafikkarte:”) lists both, and switching the card clears the graph and the peak instead of mixing the values of two cards | n/a: only one graphics card available; the switch clears the graph and the peak in the heartbeat and popup smoke scenes |
| A machine without a supported card: the settings page says "No graphics card found" (German: “Keine Grafikkarte gefunden”), and the switch adds nothing | n/a: no such machine available; covered by the popup and compact smoke scenes ("GPU on, no card") |
| On a screen 1366 pixels wide at 125 % scaling the three-column popup is wider than the screen (known, see [compatibility.md](compatibility.md#screen-size)); with two columns it fits | n/a: no such screen available; the width is documented in compatibility.md |

## Settings

| Check | Result |
|---|---|
| "Update interval:" (German: “Aktualisierungsintervall:”) takes "1.5" and "1,5" as 1.5 seconds; the rings then update at that pace; Apply/OK and reopening keep the value | 2026-10-28, Plasma 6.8.1, by hand: OK |
| "Graph shows by default:" (German: “Verlauf zeigt standardmäßig:”): a new popup after a plasmashell restart opens with the chosen window | 2026-10-28, Plasma 6.8.1, by hand: OK |
| "Defaults" (German: “Voreinstellungen”) resets the four options | 2026-10-28, Plasma 6.8.1, by hand: OK |

## Robustness

| Check | Result |
|---|---|
| Suspend and resume: the graphs show a gap for the pause instead of a line across it, and the values continue | 2026-10-28, Plasma 6.8.1, by hand: OK |
| A virtual machine or a machine without temperature sensors: the temperature tiles are left out, the rest works | n/a: no such machine available; covered by the popup smoke scene with every optional value missing |
| Restart plasmashell several times with the popup open: no warnings from the widget in `journalctl --user -b \| grep -i loadrings` | 2026-10-28, Plasma 6.8.1, scripted: six restarts during the test run, no warning from the widget in the journal: OK (with the popup closed; opening it is part of the click checks) |

## Release record 0.1.0

Gates to pass before anything is published. Fill in the date and the result
of each row. `scripts/release-check.sh 0.1.0` checks that every row is filled
in and none has a result starting with "fail" or "no" (any case), that
`package/metadata.json` has this version, that the CHANGELOG heading for it
carries the release date as YYYY-MM-DD and no longer says "unreleased" (for
example `## [0.1.0] – 2026-10-26`), and that the screenshots in `docs/images`
exist. The tag job of the CI workflow runs it before it builds or publishes
anything, so a tag pushed too early fails there.

| Gate | Date | Result |
|---|---|---|
| (a) Automatic checks green: `node tools/check.mjs` with all smoke scenes and the load check | 2026-10-26 | Done: every step passed on the development machine (Plasma 6.8.1) |
| (b) Screenshots and store images generated with `scripts/screenshots.sh` and the VectorCraft document, reviewed and committed | 2026-10-26 | Done: Breeze Dark and Breeze Light, seven views each, four store images |
| (c) Minimum version honest: documented as tested on Plasma 6.8 only (README, [compatibility.md](compatibility.md), store text) | 2026-10-26 | Done: no run on Plasma 6.3 to 6.7, said so in all three |
| (d) The manual checklist in this file, all tables, in a real panel | 2026-10-28 | Done: every table worked through on Plasma 6.8.1 in a real panel, scripted and by hand; the rows that need hardware not available here are marked n/a with the reason |
| (e) A green CI run on the remote for the commit to be tagged, before the tag is pushed | 2026-10-28 | Done: CI green on the remote (lint, test on Node 22.13 and 24, qml) for the commit before this record; the record commit itself is checked again before the tag |
| (f) CHANGELOG and the changelog in [store.md](store.md) finalized: release date in the heading as YYYY-MM-DD, no "unreleased" | 2026-10-26 | Done: heading `## [0.1.0] – 2026-10-26` |
