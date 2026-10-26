// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The applet: shows the compact view in the panel and the full view in the popup.

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "compact"
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
        onClicked: root.expanded = !root.expanded
    }
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? compactRepresentation : null

    // Fixed values until the sensors are wired up.
    readonly property var rings: [
        {
            key: "cpu",
            percent: 34
        },
        {
            key: "ram",
            percent: 58
        }
    ]

    toolTipMainText: root.tr("Load Rings")

    Component.onCompleted: console.debug("loadrings: loaded")
}
