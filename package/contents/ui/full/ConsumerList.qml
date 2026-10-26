// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The programs that use the most of something: icon, name, a note (process count or "Service"), a bar of the
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

    readonly property var translator: ({
            tr: root.tr,
            trc: root.trc,
            trp: root.trp
        })
    // The rows, for tests.
    readonly property alias rowRepeater: repeater

    spacing: 0

    Repeater {
        id: repeater

        model: root.items

        RowLayout {
            id: row

            required property var modelData

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                // Keeps the names aligned when a row has no icon.
                opacity: row.modelData.icon !== "" ? 1 : 0
                source: row.modelData.icon
            }

            QQC2.Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: row.modelData.name
                elide: Text.ElideRight
            }

            QQC2.Label {
                visible: text !== ""
                text: Popup.consumerExtra(row.modelData, root.translator)
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
                    width: track.width * Popup.barFraction(row.modelData.share)
                    height: track.height
                    radius: track.radius
                    color: Kirigami.Theme.highlightColor
                }
            }

            QQC2.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                horizontalAlignment: Text.AlignRight
                text: Popup.consumerValue(row.modelData, root.unit, Qt.locale().decimalPoint)
                font.features: { "tnum": 1 }
            }
        }
    }
}
