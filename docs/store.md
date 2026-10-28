<!--
SPDX-License-Identifier: GPL-2.0-or-later
SPDX-FileCopyrightText: 2026 Flexomatic81
-->

# KDE Store entry

The text for the entry in the KDE Store. Copy each block into the matching
field of the store form.

## Name

Load Rings

## Category

Plasma 6 Monitoring

## Version

The version in `package/metadata.json`, for example `0.1.0`.

## License

GPLv2 or later (GPL-2.0-or-later). An original product; the entry uses no
CC-BY material, so the credits field stays empty.

## Tags

```
cpu, memory, ram, gpu, load, usage, system-monitor, monitor, temperature, rings, panel, plasmoid, widget, plasma6, kde, linux
```

The store adds `plasma##majorversion=6` and the license tag (`gplv2-later`)
itself.

## Links

- Source code: https://github.com/Flexomatic81/load-rings
- File: `loadrings-<version>.plasmoid` from the GitHub release of that version

## Short description

**English**

> CPU, memory and GPU load as rings in the Plasma 6 panel, green to red. Popup with every core, graphs, top programs and hardware. No extra packages, no root.

**German**

> CPU-, Speicher- und GPU-Last als Ringe in der Plasma-6-Leiste, von Grün bis Rot. Popup mit allen Kernen, Verläufen, Top-Programmen und Hardware. Ohne Zusatzpakete und Root.

## Long description

### English

Load Rings shows the load of the processor, the memory and, if you like, the
graphics card as colored rings in the Plasma 6 panel.

- **Rings that fit:** one ring per device, sized to the panel, side by side
  or stacked in a vertical panel. The number in the middle is the load in
  percent, the color goes from green through yellow and orange to red.
- **Popup with one column per device:** usage, clock, temperature with its
  peak and the load average; a graph over 1, 5 or 15 minutes or 1 hour; the
  load of every core; where the memory goes (programs, system, cache, free),
  swap, ZRAM and memory pressure; the processor model and the memory modules.
- **Top programs:** the programs that use the most processor time and memory,
  grouped by application, with the session's background services in one row.
- **Graphics card (optional):** usage, clocks, temperatures, video memory,
  power and fan, for the card you pick.
- **Only what Plasma brings:** the values come from the system sensors and
  KDE's process model. No extra packages, no root rights, no network access,
  no serial numbers. The process list is only read while the popup is open.
- **Robust:** a missing sensor hides its line instead of breaking the view;
  stalled sensors show dashes and recover on their own.
- Few settings: update interval, the graph's default time window, the
  graphics card.
- English and German.

Requires Plasma 6.3 or newer (tested on Plasma 6.8). This is a first release
(0.1.0); reports of what works and what does not are welcome.

Source code, issues and translations: https://github.com/Flexomatic81/load-rings

### German

Load Rings zeigt die Auslastung von Prozessor, Arbeitsspeicher und auf Wunsch
der Grafikkarte als farbige Ringe in der Plasma-6-Leiste.

- **Ringe, die passen:** ein Ring je Gerät, in der Größe der Leiste,
  nebeneinander oder in einer senkrechten Leiste untereinander. Die Zahl in
  der Mitte ist die Last in Prozent, die Farbe geht von Grün über Gelb und
  Orange nach Rot.
- **Popup mit einer Spalte je Gerät:** Auslastung, Takt, Temperatur mit
  Spitzenwert und Systemlast; ein Verlauf über 1, 5 oder 15 Minuten oder
  1 Stunde; die Last jedes Kerns; wohin der Speicher geht (Programme, System,
  Cache, frei), Auslagerung, ZRAM und Speicherengpass; Prozessormodell und
  Speicherriegel.
- **Top-Programme:** die Programme, die am meisten Rechenzeit und Speicher
  brauchen, nach Anwendung gebündelt, die Hintergrunddienste der Sitzung in
  einer Zeile.
- **Grafikkarte (optional):** Auslastung, Takt, Temperaturen, Grafikspeicher,
  Leistungsaufnahme und Lüfter der gewählten Karte.
- **Nur Bordmittel von Plasma:** die Werte kommen von den Systemsensoren und
  KDEs Prozessmodell. Keine Zusatzpakete, keine Root-Rechte, kein
  Netzwerkzugriff, keine Seriennummern. Die Prozessliste wird nur bei offenem
  Popup gelesen.
- **Robust:** ein fehlender Sensor blendet seine Zeile aus, statt die Ansicht
  zu stören; hängende Sensoren zeigen Striche und erholen sich von selbst.
- Wenige Einstellungen: Aktualisierungsintervall, Zeitfenster des Verlaufs,
  Grafikkarte.
- Englisch und Deutsch.

Benötigt Plasma 6.3 oder neuer (getestet mit Plasma 6.8). Dies ist eine erste
Version (0.1.0); Rückmeldungen, was läuft und was nicht, sind willkommen.

Quellcode, Fehlermeldungen und Übersetzungen: https://github.com/Flexomatic81/load-rings

## Images

The store takes at most five images. Upload in this order; the files are in
[`store/`](store/), 1920 × 1080 each, in the stock Breeze Dark color scheme
(the fifth in Breeze Light, on a light background).

1. `store-1-overview.png`: logo, name, the three main points, the rings in
   the panel and the open popup on a desktop
2. `store-2-popup.png`: the popup with the graphics card column, its three
   columns labeled
3. `store-3-panel-views.png`: the panel views: processor and memory, with the
   graphics card, the colors from green to red with the color scale, and a
   vertical panel
4. `store-4-settings.png`: the settings page in the settings dialog, with the
   options listed beside it
5. `store-5-light.png`: the popup and the rings in Breeze Light, with what
   the widget does to stay light on the system

### How the images are made

The widget in the images is real: `scripts/screenshots.sh --store` renders
every view from the fixed demo data at three times the size into
[`store/shots/`](store/shots/): `panel.png`, `panel-gpu.png`,
`panel-vertical.png`, `panel-colors.png`, `popup.png`, `popup-gpu.png` and
`settings.png`; `scripts/screenshots.sh --store --light` renders the same
views in Breeze Light into [`store/shots/light/`](store/shots/light/) for the
fifth image. The README shows the same views at their real size from
[`images/`](images/).

Background, frames, labels and the dialog frame are drawn in
[VectorCraft](https://getartcraft.com); the document is
[`store/loadrings-store.vectorcraft`](store/loadrings-store.vectorcraft), one
artboard per image (layers "Wallpaper", "Desktop" and "Text"), with the views
embedded. After new shots, replace the embedded images (Links → Relink to the
file of the same name in `store/shots/`, or in `store/shots/light/` for the
images named "light", keeping their bounds, then Embed) and
export each artboard as PNG at scale 1, in the app or with its command line
tool:

```sh
vectorcraft-cli convert docs/store/loadrings-store.vectorcraft docs/store/store-1-overview.png --artboard 0 --scale 1
```

(`--artboard` counts from 0; 1 is the popup, 2 the panel views, 3 the
settings, 4 the light theme.) Strip the text chunks before committing (title
and creation time).

The project logo for the store page is `logo.png` (512 × 512) in
[`images/`](images/), rendered from `logo.svg` with
`rsvg-convert -w 512 -h 512 logo.svg -o logo.png`. The widget itself keeps the
theme icon `utilities-system-monitor`.

## Changelog 0.1.0

First release.

- Rings for the processor and the memory, and optionally the graphics card,
  sized to the panel and colored from green to red by load.
- A popup with one column per device: figures, graphs over up to an hour,
  the core grid, the memory breakdown, swap, ZRAM and pressure, the hardware,
  and the programs that use the most.
- A tooltip with the main values.
- Settings for the update interval, the default time window and the graphics
  card.
- Only the system sensors, KDE's process model and short reads of `/proc`,
  `/sys` and `udevadm`; no extra packages, no root rights.
- English and German.
