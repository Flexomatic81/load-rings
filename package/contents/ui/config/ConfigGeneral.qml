// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The general settings page: the update interval, the time window the graphs start with and the optional
// graphics card. Plasma opens the page with the saved values in the cfg_ properties and writes the changed ones
// back when the user applies. Every control shows its cfg_ property and writes it only on a choice of the user.

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../data"
import "../../code/sensors.mjs" as SensorCode
import "../../code/text.mjs" as TextTools

Kirigami.FormLayout {
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

    property int cfg_configVersion
    property real cfg_updateInterval
    property int cfg_historyMinutes
    property bool cfg_showGpu
    property string cfg_gpuId

    // The cards the machine has, as { text, value }; the smoke scene replaces them.
    property var gpuOptions: gpus.options

    // The controls, for the smoke scene.
    readonly property alias intervalBox: intervalSpin
    readonly property alias minutesBox: minutesChoice
    readonly property alias showGpuBox: showGpuCheck
    readonly property alias gpuBox: gpuChoice
    readonly property alias noGpuLabel: noGpuHint

    // Reads the graphics cards from the sensor tree.
    GpuChoices {
        id: gpus
    }

    // In tenths of a second, from 0.5 s to 10 s; the setting is in seconds.
    QQC2.SpinBox {
        id: intervalSpin

        Kirigami.FormData.label: root.tr("Update interval:")
        from: 5
        to: 100
        stepSize: 5
        value: Math.round(root.cfg_updateInterval * 10)
        // The box counts tenths of a second; the text shows seconds.
        valueFromText: (text, locale) => Math.round(TextTools.parseSpinText(text, locale, 1, intervalSpin.value / 10) * 10)
        textFromValue: (value, locale) => root.trc("@item:valuesuffix %1 is a number of seconds", "%1 s", Number(value / 10).toLocaleString(locale, "f", 1))
        onValueModified: root.cfg_updateInterval = intervalSpin.value / 10
    }

    ConfigComboBox {
        id: minutesChoice

        Kirigami.FormData.label: root.tr("Graph shows by default:")
        options: [
            {
                text: root.trc("@item:inlistbox time span of the graph", "1 minute"),
                value: 1
            },
            {
                text: root.trc("@item:inlistbox time span of the graph", "5 minutes"),
                value: 5
            },
            {
                text: root.trc("@item:inlistbox time span of the graph", "15 minutes"),
                value: 15
            },
            {
                text: root.trc("@item:inlistbox time span of the graph", "1 hour"),
                value: 60
            }
        ]
        configValue: root.cfg_historyMinutes
        onPicked: value => root.cfg_historyMinutes = value
    }

    QQC2.CheckBox {
        id: showGpuCheck

        text: root.tr("Show graphics card")
        checked: root.cfg_showGpu
        onToggled: root.cfg_showGpu = showGpuCheck.checked
    }

    ConfigComboBox {
        id: gpuChoice

        Kirigami.FormData.label: root.tr("Graphics card:")
        options: root.gpuOptions
        // An empty setting means the first card.
        configValue: SensorCode.pickGpu(root.gpuOptions.map(option => option.value), root.cfg_gpuId)
        enabled: root.cfg_showGpu && root.gpuOptions.length > 1
        onPicked: value => root.cfg_gpuId = value
    }

    QQC2.Label {
        id: noGpuHint

        visible: root.gpuOptions.length === 0
        text: root.tr("No graphics card found")
        wrapMode: Text.Wrap
        opacity: 0.7
    }
}
