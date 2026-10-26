// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The processor column of the popup: model and topology, the figures, the usage graph, the core grid, the kernel
// details and the programs that use the CPU. Parts without a value are left out.

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/apps.mjs" as Apps
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
    // The points of the graph window ({ times, cpu }), its span in minutes and its right end in ms.
    property var graphWindow: ({
            times: [],
            cpu: []
        })
    property int graphMinutes: 5
    property real graphNow: 0
    // The highest CPU temperature since the start, or null.
    property var peakTemperature: null
    // ProcStats.stats (or null) and the context switches per second (NaN when unknown).
    property var stats: null
    property real ctxtPerSecond: NaN
    // HardwareInfo.info, or null.
    property var hardwareInfo: null
    // AppsSource.rows.
    property var appRows: []

    // The user picked another time window.
    signal graphMinutesPicked(int minutes)

    readonly property var translator: ({
            tr: root.tr,
            trc: root.trc,
            trp: root.trp
        })
    readonly property string decimalPoint: Qt.locale().decimalPoint
    readonly property var cores: root.current.cores ?? []
    readonly property var consumerItems: Apps.topConsumers(root.appRows, "cpu", 100)

    // Parts for the smoke scenes.
    readonly property QQC2.Label modelLabel: modelText
    readonly property QQC2.Label topologyLabel: topologyText
    readonly property StatTile usageTile: usage
    readonly property StatTile clockTile: clock
    readonly property StatTile temperatureTile: temperature
    readonly property StatTile loadTile: load
    readonly property CoreGrid coreGrid: grid
    readonly property QQC2.Label detailsLabel: details
    readonly property ConsumerList consumerList: consumers

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            text: root.tr("CPU")
            font.bold: true
        }

        QQC2.Label {
            id: modelText

            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.hardwareInfo?.cpuModel ?? ""
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
        }

        QQC2.Label {
            id: topologyText

            visible: text !== ""
            text: Popup.cpuTopology(root.hardwareInfo?.physicalCores, root.current.coreCount, root.translator)
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.disabledTextColor
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
            value: Popup.withUnit(Format.formatPercent(root.current.cpuUsage, root.decimalPoint), "%")
            valueColor: Color.ringColor(root.current.cpuUsage) ?? Kirigami.Theme.textColor
        }

        StatTile {
            id: clock

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            visible: Popup.tileShown(root.current.cpuFrequency, root.fresh)
            label: root.tr("Clock")
            value: Format.formatGHz(root.current.cpuFrequency, root.decimalPoint)
            detail: Popup.clockDetail(root.current.cpuMaxFrequency, root.translator, root.decimalPoint)
        }

        StatTile {
            id: temperature

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            visible: Popup.tileShown(root.current.cpuTemperature, root.fresh) || root.peakTemperature !== null
            label: root.tr("Temperature")
            value: Format.formatTemp(root.current.cpuTemperature)
            detail: Popup.peakDetail(root.peakTemperature, root.translator)
        }

        StatTile {
            id: load

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            visible: (root.stats?.loadavg ?? null) !== null
            label: root.tr("Load 1/5/15")
            value: Popup.loadText(root.stats?.loadavg, root.decimalPoint)
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
        values: root.graphWindow.cpu
        minutes: root.graphMinutes
        now: root.graphNow
        color: Kirigami.Theme.highlightColor
    }

    QQC2.Label {
        Layout.topMargin: Kirigami.Units.smallSpacing
        visible: grid.visible
        text: root.tr("Cores")
        font.bold: true
    }

    CoreGrid {
        id: grid

        Layout.fillWidth: true
        visible: root.cores.length > 0
        cores: root.cores
    }

    QQC2.Label {
        id: details

        Layout.fillWidth: true
        visible: text !== ""
        text: Popup.cpuDetails(root.stats, root.ctxtPerSecond, root.translator, root.decimalPoint)
        font: Kirigami.Theme.smallFont
        color: Kirigami.Theme.disabledTextColor
        wrapMode: Text.WordWrap
    }

    QQC2.Label {
        Layout.topMargin: Kirigami.Units.smallSpacing
        visible: consumers.visible
        text: root.tr("What uses the CPU")
        font.bold: true
    }

    ConsumerList {
        id: consumers

        Layout.fillWidth: true
        visible: root.consumerItems.length > 0
        items: root.consumerItems
        unit: "percent"
    }
}
