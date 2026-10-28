<!--
SPDX-License-Identifier: GPL-2.0-or-later
SPDX-FileCopyrightText: 2026 Flexomatic81
-->

# Compatibility

## Supported versions

Load Rings needs **Plasma 6.3 or newer**, with
**KDE Frameworks 6.10 or newer** and **Qt 6.7 or newer**.

- Qt 6.7 is the hard floor of the code: the memory bar rounds the outer
  corners of its first and last part with the per-corner radii of
  `Rectangle` (`topLeftRadius` and the like), which Qt Quick has since 6.7.
- Plasma 6.3 and Frameworks 6.10 are the minimum of the sibling widget this
  one is built like; the modules and types listed below are the same kinds it
  uses, with libksysguard's process model as the only addition.

### What has been tested, and what has not

Load Rings has run on **Plasma 6.8 with KDE Frameworks 6.31 and Qt 6.12**
only. No release has been run on Plasma 6.3 to 6.7, and unlike the minimum
of the sibling widget, the list below has not been checked line by line
against the source code of those releases. If you use one of these versions,
the [checklist at the end](#checklist-for-an-older-plasma-version) lists what
to look at; reports of what works and what does not are welcome as an issue.

### `X-Plasma-API-Minimum-Version` stays at `6.0`

`package/metadata.json` sets `"X-Plasma-API-Minimum-Version": "6.0"`. That key
names the generation of the applet API, not a Plasma release, and it is not a
gate for the minimum above: libplasma reads it only to word the error message
after an applet has failed to load, and the widget explorer hides only widgets
whose major version is not 6. `6.0` is the value the Plasma 6 templates use.
The minimum is stated here and in the README instead.

### Screen size

The popup has one column of 22 grid units per device. With the graphics card
it has three columns, about 68 grid units or 1225 pixels at the default font
size. On a small screen or with a high scale factor (for example 1366 pixels
wide at 125 %) such a popup is wider than the screen; switch the graphics card
off there, which leaves two columns of about 830 pixels.

## Inventory

### QML modules

| Module | Used for |
| --- | --- |
| `QtQuick`, `QtQuick.Layouts`, `QtQuick.Controls`, `QtQml.Models` | Items, layouts, controls, `Instantiator`, `Repeater`; `Rectangle` with per-corner radii (Qt 6.7) |
| `QtQuick.Shapes` | The usage graphs (`Shape`, `ShapePath`, `PathSvg`) and the panel rings |
| `org.kde.kirigami` | `FormLayout`, `Theme` colors and fonts, `Units`, `Icon` |
| `org.kde.kcmutils` | `SimpleKCM` as the root of the settings page |
| `org.kde.plasma.plasmoid` | `PlasmoidItem` with `compactRepresentation`, `fullRepresentation`, `preferredRepresentation`, `expanded`, `toolTipMainText`, `toolTipSubText`; `Plasmoid.configuration`, `formFactor` |
| `org.kde.plasma.core` | `Types.Vertical`, `Types.Planar` |
| `org.kde.plasma.components` | `Label` for the number in the panel rings (the Plasma font, as in the sibling widgets) |
| `org.kde.plasma.configuration` | `ConfigModel`, `ConfigCategory` in `config/config.qml` |
| `org.kde.plasma.plasma5support` | `DataSource` with `engine: "executable"` (only in `CommandRunner.qml`, loaded with a fallback) |
| `org.kde.ksysguard.sensors` | `Sensor` (`sensorId`, `value`, `status`, `updateRateLimit`), `SensorTreeModel` (role `SensorId`) for the list of graphics cards |
| `org.kde.ksysguard.process` | `ApplicationDataModel` for the programs in the popup (created only while the popup is open), with the roles `ProcessDataModel.Value` and `ProcessDataModel.PIDs` |

### Contracts that are not documented API

| Contract | Used for |
| --- | --- |
| Sensor IDs `cpu/all/usage`, `cpu/all/averageFrequency`, `cpu/all/averageTemperature`, `cpu/all/coreCount` | The processor ring, tiles and tooltip |
| Sensor IDs `cpu/cpu<N>/usage`, `frequency`, `temperature` | The core grid; read only while the popup is open |
| Sensor IDs `memory/physical/total`, `memory/physical/used`, `memory/physical/application`, `memory/physical/usedPercent`, `memory/swap/total`, `memory/swap/used` | The memory ring, the memory column and the tooltip |
| Sensor IDs `gpu/gpu<N>/name`, `usage`, `temperature`, `temp2`, `temp3`, `coreFrequency`, `memoryFrequency`, `usedVram`, `totalVram`, `power`, `fan1` | The graphics card ring and column; the cards are found in the sensor tree |
| Sensor ID `os/system/uptime` | Heartbeat that tells stalled sensors from values that do not change |
| The usage of the application model counts per core (100 = one core busy) | The processor share of a program, divided by the number of logical cores (measured with libksysguard 6.8.1) |
| The application model lists the cgroups of the user's systemd instance only | Programs and the "Background services" row; system services are not listed |
| Executable engine data keys `exit code`, `stdout`, `stderr` | `CommandRunner.qml`; the engine ships with plasma-workspace |
| `udevadm info` lists `MEMORY_DEVICE_<n>_*` properties of `/sys/devices/virtual/dmi/id` without root | The memory modules in the memory column header |

### QML and JavaScript language features

| Feature | Available since |
| --- | --- |
| `Rectangle.topLeftRadius` and the other per-corner radii | Qt 6.7 |
| `pragma ComponentBehavior: Bound` | Qt 6.4 |
| Typed function parameters and return types, `required property`, `Connections` with `function onX()` handlers | Qt 5.15 |
| `??` and `?.` | `??` Qt 5.15, `?.` Qt 6.2 |
| Arrow functions, rest and spread arguments, template literals, `.mjs` modules imported into QML | Qt 5.12 |
| `Item.grabToImage` | Qt 5.4; in `tools/screenshots` only, not shipped |

The `.mjs` modules avoid object spread and `Array.prototype.at`, which the QML
engine of these versions does not take.

## Checklist for an older Plasma version

Not part of the release checks: no release has been run through this list.
Use a test user; note the result of every line.

**Setup**

- [ ] Record the versions: `plasmashell --version`, the Frameworks version
      and the Qt version (for example with
      `dpkg-query -W plasma-workspace 'libkf6coreaddons6*' 'libqt6core6*'`).
      They must be at least Plasma 6.3, Frameworks 6.10 and Qt 6.7.
- [ ] Build the package on the development machine with
      `scripts/build-plasmoid.sh <version>`, copy
      `dist/loadrings-<version>.plasmoid` to the test machine and install it
      with `kpackagetool6 --type Plasma/Applet --install loadrings-<version>.plasmoid`.
      Log out and in again.
- [ ] Add "Load Rings" from the widget explorer to a panel. It is listed and
      loads without an error box.
- [ ] `journalctl --user -b | grep -i loadrings` shows no QML warning about a
      missing module, type or property.

**Panel and popup**

- [ ] Horizontal panel: two rings with numbers, colored by load.
- [ ] Vertical panel: the rings are stacked, nothing is cut off.
- [ ] The tooltip shows the processor and memory lines.
- [ ] A click opens the popup: both columns with figures, graphs, core grid,
      memory bar (rounded ends), swap and the program lists. The time window
      buttons switch the graphs.
- [ ] The "Open System Monitor" button starts the system monitor.

**Settings**

- [ ] The settings page opens; the interval takes "1.5" (or "1,5" in German).
- [ ] "Show graphics card" adds a third ring and a third column on a machine
      with a supported card.

**Data sources**

- [ ] Stop the sensor service while the widget runs
      (`systemctl --user stop plasma-ksystemstats`): after a few seconds the
      rings show dashes. Start it again: the values come back.
- [ ] Without `plasma5support` (if the distribution splits it off) the widget
      still loads and shows the rings.

**German**

- [ ] Switch the system language to German, log out and in: tooltip, popup
      and settings are in German, numbers use a decimal comma.
