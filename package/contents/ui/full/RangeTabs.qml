// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The switches for the time window of the graphs: 1 min, 5 min, 15 min, 1 h.

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import "../../code/text.mjs" as TextTools

Row {
    id: root

    // Translation helper: the only place that calls Plasma's i18n functions.
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

    // The window shown, in minutes.
    property int minutes: 5

    // The user picked another window.
    signal picked(int minutes)

    readonly property var choices: [
        {
            minutes: 1,
            label: root.tr("1 min")
        },
        {
            minutes: 5,
            label: root.tr("5 min")
        },
        {
            minutes: 15,
            label: root.tr("15 min")
        },
        {
            minutes: 60,
            label: root.tr("1 h")
        }
    ]

    spacing: 2

    Repeater {
        id: buttons

        model: root.choices

        QQC2.ToolButton {
            id: button

            required property var modelData

            text: button.modelData.label
            checkable: true
            checked: root.minutes === button.modelData.minutes
            onClicked: root.picked(button.modelData.minutes)
        }
    }
}
