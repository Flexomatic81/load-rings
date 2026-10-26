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

- Version:
- Date:
- Plasma version:

## Panel

| Check | Result |
|---|---|
| Horizontal panel at the default height: two rings with numbers; the numbers change without the panel jumping | |
| Vertical panel: the rings are stacked in one column, nothing is cut off | |
| Panel sizes: horizontal about 24 px, 44 px and 96 px, vertical about 32 px wide: the numbers stay readable | |
| Desktop: the widget shows the rings side by side | |
| Light and dark theme (Breeze Light, Breeze Dark): the numbers and the empty part of the rings are easy to see in both | |
| Load the processor (for example `stress-ng --cpu 0` or a build): the processor ring turns from green through yellow and orange to red and back | |
| Tooltip: the lines "CPU" (German: “CPU”), "RAM" and, with the graphics card shown, "GPU" with their values | |
| Stop the sensor service (`systemctl --user stop plasma-ksystemstats`): after a few seconds the rings show a dash and the tooltip says "No data from the system sensors" (German: “Keine Daten von den Systemsensoren”); start it again: the values come back without a restart | |

## Popup

| Check | Result |
|---|---|
| A click on the rings opens the popup; another click closes it and does not reopen it right away; a click outside closes it as well | |
| Processor column: model, cores and threads, usage, clock, temperature with peak, load average; the graph fills over time | |
| Core grid: one cell per logical core; hovering a cell shows its clock and temperature | |
| The detail line names the governor, the energy preference (where the system has one), the context switches per second and the waiting time | |
| "What uses the CPU" (German: “Wer belastet die CPU”) and "What uses the memory" (German: “Wer belegt den Speicher”): the programs match what the System Monitor shows under Applications, a program with several processes is one row, and "Background services" (German: “Hintergrunddienste”) collects the session's services | |
| Memory column: the header names type, speed and modules where the firmware tells them; the bar parts add up to the whole width; swap, ZRAM and pressure rows show where the system has them | |
| Switch the time window between 1 min, 5 min, 15 min and 1 h: all graphs follow; the window in the settings stays as it was | |
| "Open System Monitor" (German: “Systemmonitor öffnen”) starts the System Monitor | |
| With the popup closed, `ps` shows no shell command of the widget running at each interval, and the System Monitor shows no extra load from plasmashell | |
| German system language: all texts of the popup are German, numbers use a decimal comma, nothing is cut off | |

## Graphics card

| Check | Result |
|---|---|
| Settings → "Show graphics card" (German: “Grafikkarte anzeigen”): a third ring and a third popup column appear; switching it off removes both | |
| The column shows the name, usage, clock, temperature with peak, power, video memory and the detail line; values the card does not report are left out | |
| A machine with two cards: "Graphics card:" (German: “Grafikkarte:”) lists both, and switching the card clears the graph and the peak instead of mixing the values of two cards | |
| A machine without a supported card: the settings page says "No graphics card found" (German: “Keine Grafikkarte gefunden”), and the switch adds nothing | |
| On a screen 1366 pixels wide at 125 % scaling the three-column popup is wider than the screen (known, see [compatibility.md](compatibility.md#screen-size)); with two columns it fits | |

## Settings

| Check | Result |
|---|---|
| "Update interval:" (German: “Aktualisierungsintervall:”) takes "1.5" and "1,5" as 1.5 seconds; the rings then update at that pace; Apply/OK and reopening keep the value | |
| "Graph shows by default:" (German: “Verlauf zeigt standardmäßig:”): a new popup after a plasmashell restart opens with the chosen window | |
| "Defaults" (German: “Voreinstellungen”) resets the four options | |

## Robustness

| Check | Result |
|---|---|
| Suspend and resume: the graphs show a gap for the pause instead of a line across it, and the values continue | |
| A virtual machine or a machine without temperature sensors: the temperature tiles are left out, the rest works | |
| Restart plasmashell several times with the popup open: no warnings from the widget in `journalctl --user -b \| grep -i loadrings` | |

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
| (d) The manual checklist in this file, all tables, in a real panel | | |
| (e) A green CI run on the remote for the commit to be tagged, before the tag is pushed | | |
| (f) CHANGELOG and the changelog in [store.md](store.md) finalized: release date in the heading as YYYY-MM-DD, no "unreleased" | 2026-10-26 | Done: heading `## [0.1.0] – 2026-10-26` |
