// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The graphics card column of the popup: name, the figures, the usage graph, the video memory and the details
// (memory clock, temperatures, fan). Parts without a value are left out; there is no process list.

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/color.mjs" as Color
import "../../code/format.mjs" as Format
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

    // The sensor snapshot (SystemSensors.current) and whether the sensors are fresh.
    property var current: ({})
    property bool fresh: false
    // The points of the graph window ({ times, gpu }), its span in minutes and its right end in ms. Empty when the
    // history belongs to another card.
    property var graphWindow: ({
            times: [],
            gpu: []
        })
    property int graphMinutes: 5
    property real graphNow: 0
    // The highest GPU temperature of this card since it was chosen, or null.
    property var peakTemperature: null

    // The user picked another time window.
    signal graphMinutesPicked(int minutes)

    readonly property var translator: ({
            tr: root.tr,
            trc: root.trc,
            trp: root.trp
        })
    readonly property string decimalPoint: Qt.locale().decimalPoint
    readonly property string groupSeparator: Qt.locale().groupSeparator
    readonly property var gpu: root.current.gpu ?? ({})

    // Parts for the smoke scenes.
    readonly property QQC2.Label nameLabel: nameText
    readonly property StatTile usageTile: usage
    readonly property StatTile clockTile: clock
    readonly property StatTile temperatureTile: temperature
    readonly property StatTile powerTile: power
    readonly property MeterRow memoryRow: memory
    readonly property QQC2.Label detailsLabel: details

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            text: root.tr("GPU")
            font.bold: true
        }

        QQC2.Label {
            id: nameText

            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.gpu.name ?? ""
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        StatTile {
            id: usage

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            label: root.tr("Usage")
            value: Popup.withUnit(Format.formatPercent(root.gpu.usage, root.decimalPoint), "%")
            valueColor: Color.ringColor(root.gpu.usage) ?? Kirigami.Theme.textColor
        }

        StatTile {
            id: clock

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            visible: Popup.tileShown(root.gpu.coreFrequency, root.fresh)
            label: root.tr("Clock")
            value: Format.formatGHz(root.gpu.coreFrequency, root.decimalPoint)
            detail: "GHz"
        }

        StatTile {
            id: temperature

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            visible: Popup.tileShown(root.gpu.temperature, root.fresh) || root.peakTemperature !== null
            label: root.tr("Temperature")
            value: Format.formatTemp(root.gpu.temperature)
            detail: Popup.peakDetail(root.peakTemperature, root.translator, root.gpu.temperature)
        }

        StatTile {
            id: power

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            visible: Popup.tileShown(root.gpu.power, root.fresh)
            label: root.tr("Power")
            value: Popup.powerText(root.gpu.power)
        }
    }

    RangeTabs {
        Layout.alignment: Qt.AlignRight
        minutes: root.graphMinutes
        onPicked: minutes => root.graphMinutesPicked(minutes)
    }

    UsageGraph {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 4
        times: root.graphWindow.times
        values: root.graphWindow.gpu
        minutes: root.graphMinutes
        now: root.graphNow
        color: Kirigami.Theme.activeTextColor
    }

    MeterRow {
        id: memory

        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        visible: Popup.vramShown(root.gpu.totalVram, root.fresh)
        label: root.tr("Video memory")
        labelWidth: Kirigami.Units.gridUnit * 6
        fraction: Popup.vramFraction(root.gpu.usedVram, root.gpu.totalVram)
        barColor: Color.ringColor(Popup.vramPercent(root.gpu.usedVram, root.gpu.totalVram)) ?? Kirigami.Theme.highlightColor
        text: Popup.vramText(root.gpu.usedVram, root.gpu.totalVram, root.translator, root.decimalPoint)
    }

    QQC2.Label {
        id: details

        Layout.fillWidth: true
        visible: details.text !== ""
        text: Popup.gpuDetails(root.gpu, root.translator, root.decimalPoint, root.groupSeparator)
        font: Kirigami.Theme.smallFont
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
    }
}
