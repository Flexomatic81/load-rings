// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// A bar divided into the parts of a total, with a legend below it that names each part and its size.

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/popup.mjs" as Popup
import "../../code/text.mjs" as TextTools

ColumnLayout {
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

    // The parts, left to right: [{ key, bytes }] (memoryBreakdown()); their sum is the total.
    property var segments: []
    property real total: 0
    // The colour of each part by its key: { apps: color, ... }. A part without one is not drawn.
    property var colors: ({})

    readonly property var translator: ({
            tr: root.tr,
            trc: root.trc,
            trp: root.trp
        })
    readonly property string decimalPoint: Qt.locale().decimalPoint
    // For the smoke scene: the segments and the width of the bar.
    readonly property alias segmentRepeater: segmentItems
    readonly property real barWidth: track.width

    spacing: Kirigami.Units.smallSpacing / 2

    Rectangle {
        id: track

        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 0.6)
        radius: 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

        Row {
            Repeater {
                id: segmentItems

                // The count, not the list: new values must not rebuild the segments.
                model: root.segments.length

                Rectangle {
                    id: part

                    required property int index
                    readonly property var segment: root.segments[part.index] ?? null

                    width: part.segment !== null && root.total > 0 ? track.width * part.segment.bytes / root.total : 0
                    height: track.height
                    color: part.segment !== null ? (root.colors[part.segment.key] ?? "transparent") : "transparent"
                }
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        Repeater {
            model: root.segments.length

            Row {
                id: entry

                required property int index
                readonly property var segment: root.segments[entry.index] ?? null

                visible: entry.segment !== null && entry.segment.bytes > 0
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Kirigami.Units.smallSpacing * 1.5
                    height: width
                    radius: width / 2
                    color: entry.segment !== null ? (root.colors[entry.segment.key] ?? "transparent") : "transparent"
                }

                QQC2.Label {
                    text: entry.segment !== null ? Popup.legendText(entry.segment, root.translator, root.decimalPoint) : ""
                    font: Kirigami.Theme.smallFont
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }
    }
}
