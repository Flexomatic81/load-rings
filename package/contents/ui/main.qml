// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The applet: shows the compact view in the panel and the full view in the popup.

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "compact"
import "data"
import "full"
import "../code/text.mjs" as TextTools

PlasmoidItem {
    id: root

    // Translation helpers: the only place that calls Plasma's i18n functions.
    // Plain qml6 (the smoke scenes) has none and gets the English text.
    function tr(text: string, ...args): string {
        // Plasma context function, not declared for qmllint
        return typeof i18n === "function" ? i18n(text, ...args) : TextTools.substitute(text, args); // qmllint disable unqualified
    }
    function trc(context: string, text: string, ...args): string {
        // Plasma context function, not declared for qmllint
        return typeof i18nc === "function" ? i18nc(context, text, ...args) : TextTools.substitute(text, args); // qmllint disable unqualified
    }
    function trp(singular: string, plural: string, n: int, ...args): string {
        // Plasma context function, not declared for qmllint
        return typeof i18np === "function" ? i18np(singular, plural, n, ...args) : TextTools.pluralFallback(singular, plural, n, args); // qmllint disable unqualified
    }

    // Plasma 6 only instantiates compactRepresentation when a
    // fullRepresentation exists.
    fullRepresentation: FullRepresentation {}
    compactRepresentation: CompactRepresentation {
        rings: root.rings
        vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        onDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar
        onPressed: root.wasExpanded = root.expanded
        // Plasma collapses an open popup on the press, so toggle from the state noted then
        onClicked: root.expanded = !root.wasExpanded
    }
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? compactRepresentation : null

    // The state of the popup at the last press (see CompactRepresentation).
    property bool wasExpanded: false

    // The sensor values; everything shown reads sensors.current, which is NaN while the sensors look stalled.
    SystemSensors {
        id: sensors

        // Plasmoid.configuration is generated from main.xml at runtime, which qmllint cannot see
        interval: Plasmoid.configuration.updateInterval * 1000 // qmllint disable missing-property
        gpuEnabled: Plasmoid.configuration.showGpu // qmllint disable missing-property
        gpuWanted: Plasmoid.configuration.gpuId // qmllint disable missing-property
    }

    readonly property bool gpuShown: sensors.gpuId !== ""
    readonly property var rings: root.gpuShown ? [
        {
            key: "cpu",
            percent: sensors.current.cpuUsage
        },
        {
            key: "ram",
            percent: sensors.current.memUsedPercent
        },
        {
            key: "gpu",
            percent: sensors.current.gpu.usage
        }
    ] : [
        {
            key: "cpu",
            percent: sensors.current.cpuUsage
        },
        {
            key: "ram",
            percent: sensors.current.memUsedPercent
        }
    ]

    toolTipMainText: root.tr("Load Rings")

    Component.onCompleted: console.debug("loadrings: loaded")
}
