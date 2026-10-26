// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The programs that use the most of something: icon, name, a note (the process count), a bar of the
// share and the value.

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

    // The result of topConsumers(): [{ name, icon, kind, processCount, value, share }].
    property var items: []
    // How the values read: "percent" or "bytes".
    property string unit: "percent"
    // The most rows the list shows.
    property int limit: 5
    // True while the programs can be read: the list then always lays out `limit` rows, blank until the values
    // arrive, so it does not grow a few seconds after the popup opens.
    property bool reserved: false

    readonly property var translator: ({
            tr: root.tr,
            trc: root.trc,
            trp: root.trp
        })
    // Shown by a row whose entry is gone for a moment while the list is rebuilt.
    readonly property var emptyItem: ({
            name: "",
            icon: "",
            kind: "app",
            processCount: 0,
            value: NaN,
            share: null
        })
    // The rows, for tests.
    readonly property alias rowRepeater: repeater
    // The rows laid out.
    readonly property int rowCount: root.reserved ? Math.max(root.limit, root.items.length) : root.items.length

    spacing: 0

    Repeater {
        id: repeater

        // The count, not the list: new values must not rebuild the rows and reload their icons.
        model: root.rowCount

        RowLayout {
            id: row

            required property int index
            readonly property var item: root.items[row.index] ?? root.emptyItem

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            // A row without a program keeps its room but shows nothing.
            opacity: row.index < root.items.length ? 1 : 0

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                // Keeps the names aligned when a row has no icon.
                opacity: row.item.icon !== "" ? 1 : 0
                source: row.item.icon
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: row.item.name
                elide: Text.ElideRight
            }

            QQC2.Label {
                id: extra

                visible: extra.text !== ""
                text: Popup.consumerExtra(row.item, root.translator)
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.disabledTextColor
            }

            Rectangle {
                id: track

                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                Layout.preferredHeight: Math.round(Kirigami.Units.smallSpacing * 1.5)
                radius: track.height / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

                Rectangle {
                    width: track.width * Popup.barFraction(row.item.share)
                    height: track.height
                    radius: track.radius
                    color: Kirigami.Theme.highlightColor
                }
            }

            QQC2.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                horizontalAlignment: Text.AlignRight
                text: Popup.consumerValue(row.item, root.unit, Qt.locale().decimalPoint)
                font.features: { "tnum": 1 }
            }
        }
    }
}
