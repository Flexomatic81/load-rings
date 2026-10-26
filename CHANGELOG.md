<!--
SPDX-License-Identifier: GPL-2.0-or-later
SPDX-FileCopyrightText: 2026 Flexomatic81
-->

# Changelog

## [Unreleased]

## [0.1.0] – 2026-10-26

First release.

### Added

- Rings in the panel for the processor and the memory, and optionally the
  graphics card: the load in percent in the middle, the color from green
  (0 %) through yellow (50 %) and orange (75 %) to red (100 %). The rings
  follow the panel size, in a row in a horizontal panel and stacked in a
  vertical one.
- A tooltip with the main values of each device.
- A popup with one column per device: usage, clock, temperature with its peak
  and load average; graphs over 1, 5 or 15 minutes or 1 hour, kept in memory
  for up to an hour; the load of every core; the memory split into programs,
  system, cache and free, with swap, ZRAM and memory pressure; the processor
  model and the memory modules; video memory, power and fan of the graphics
  card.
- The programs that use the most processor time and memory, grouped by
  application, with the session's background services in one row.
- Settings for the update interval (0.5 to 10 seconds), the time window the
  graphs start with, and whether and which graphics card is shown.
- The values come from the system sensors and KDE's process model; the
  process list, the per-core sensors and the short reads of `/proc`, `/sys`
  and `udevadm` run only while the popup is open. No extra packages, no root
  rights, no network access, no serial numbers.
- Missing sensors hide their line; stalled sensors show dashes and recover on
  their own.
- English and German.
