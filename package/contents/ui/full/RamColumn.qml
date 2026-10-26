// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The memory column of the popup: the modules, how much is used and what it consists of, the usage graph, swap,
// ZRAM and memory pressure, and the programs that use the most memory. Parts without a value are left out.

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/apps.mjs" as Apps
import "../../code/color.mjs" as Color
import "../../code/format.mjs" as Format
import "../../code/memory.mjs" as Memory
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
    // The points of the graph window ({ times, ram }), its span in minutes and its right end in ms.
    property var graphWindow: ({
            times: [],
            ram: []
        })
    property int graphMinutes: 5
    property real graphNow: 0
    // ProcStats.stats (or null).
    property var stats: null
    // HardwareInfo.info, or null.
    property var hardwareInfo: null
    // AppsSource.rows, and whether the programs can be read at all (AppsSource.available).
    property var appRows: []
    property bool appsAvailable: false

    // The user picked another time window.
    signal graphMinutesPicked(int minutes)

    readonly property var translator: ({
            tr: root.tr,
            trc: root.trc,
            trp: root.trp
        })
    readonly property string decimalPoint: Qt.locale().decimalPoint
    // Read once so the ranking is computed again only when the total or the rows change, not on every tick.
    readonly property real liveTotal: root.current.memTotal ?? NaN
    // The last total the sensors reported: it stays while they are stale, so the header and the shares keep their
    // basis, and it only changes (and so only recomputes the ranking) when the total itself changes.
    property real memTotal: NaN
    readonly property var consumerItems: Apps.topConsumers(root.appRows, "memory", root.memTotal, consumers.limit)
    readonly property var segments: Memory.memoryBreakdown({
            total: root.current.memTotal,
            used: root.current.memUsed,
            application: root.current.memApplication,
            memFree: root.stats?.memFree
        })
    readonly property var zram: Popup.zramDevices(root.stats?.zram)
    readonly property real swapFraction: root.current.swapTotal > 0 ? root.current.swapUsed / root.current.swapTotal : 0
    readonly property real pressure: root.stats?.psiMemory ?? NaN
    readonly property color usedColor: Color.ringColor(root.current.memUsedPercent) ?? Kirigami.Theme.textColor
    readonly property var segmentColors: ({
            apps: Color.ringColor(root.current.memUsedPercent) ?? Kirigami.Theme.highlightColor,
            other: Color.SYSTEM_MEMORY_COLOR,
            cache: Qt.alpha(Kirigami.Theme.textColor, 0.35),
            free: Qt.alpha(Kirigami.Theme.textColor, 0.12),
            available: Qt.alpha(Kirigami.Theme.textColor, 0.12)
        })

    // Parts for the smoke scenes.
    readonly property QQC2.Label headLabel: head
    readonly property QQC2.Label usedLabel: usedText
    readonly property QQC2.Label percentLabel: percentText
    readonly property StackedBar stackedBar: bar
    readonly property MeterRow swapRow: swap
    readonly property Repeater zramRepeater: zramRows
    readonly property MeterRow pressureRow: waiting
    readonly property ConsumerList consumerList: consumers

    spacing: Kirigami.Units.smallSpacing

    onLiveTotalChanged: root.rememberTotal()
    Component.onCompleted: root.rememberTotal()

    function rememberTotal() {
        if (Number.isFinite(root.liveTotal)) {
            root.memTotal = root.liveTotal;
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            text: root.tr("Memory")
            font.bold: true
        }

        QQC2.Label {
            id: head

            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: Popup.memoryHeader(root.hardwareInfo?.memory, root.memTotal, root.translator, root.decimalPoint)
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: Popup.tileShown(root.current.memUsed, root.fresh)
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            id: usedText

            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: Popup.usedLine(root.current.memUsed, root.current.memTotal, root.translator, root.decimalPoint)
            color: root.usedColor
            font.pixelSize: Math.round(Kirigami.Units.gridUnit * 1.1)
            font.weight: Font.Light
            font.features: { "tnum": 1 }
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit * 0.6)
        }

        QQC2.Label {
            id: percentText

            Layout.alignment: Qt.AlignBottom
            text: Popup.withUnit(Format.formatPercent(root.current.memUsedPercent, root.decimalPoint), "%")
            color: Kirigami.Theme.disabledTextColor
            font.features: { "tnum": 1 }
        }
    }

    StackedBar {
        id: bar

        Layout.fillWidth: true
        visible: Popup.tileShown(root.current.memUsed, root.fresh)
        segments: root.segments
        total: root.current.memTotal ?? 0
        colors: root.segmentColors
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
        values: root.graphWindow.ram
        minutes: root.graphMinutes
        now: root.graphNow
        color: Kirigami.Theme.positiveTextColor
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        MeterRow {
            id: swap

            Layout.fillWidth: true
            visible: Popup.swapShown(root.current.swapTotal, root.fresh)
            label: root.tr("Swap")
            fraction: root.swapFraction
            barColor: Color.ringColor(root.swapFraction * 100) ?? Kirigami.Theme.highlightColor
            text: Popup.swapText(root.current.swapUsed, root.current.swapTotal, root.translator, root.decimalPoint)
        }

        Repeater {
            id: zramRows

            // The count, not the list: new values must not rebuild the rows.
            model: root.zram.length

            MeterRow {
                id: zramRow

                required property int index
                readonly property var device: root.zram[zramRow.index] ?? ({})

                Layout.fillWidth: true
                label: Popup.zramLabel(zramRow.device.name ?? "", root.zram.length, root.translator)
                fraction: Popup.zramFraction(zramRow.device, root.memTotal)
                text: Popup.zramText(zramRow.device, root.translator, root.decimalPoint)
            }
        }

        MeterRow {
            id: waiting

            Layout.fillWidth: true
            visible: root.pressure >= 0
            label: root.tr("Pressure")
            fraction: root.pressure / 100
            barColor: Color.ringColor(root.pressure) ?? Kirigami.Theme.highlightColor
            text: Popup.pressureText(root.pressure, root.translator, root.decimalPoint)
        }
    }

    QQC2.Label {
        Layout.topMargin: Kirigami.Units.smallSpacing
        visible: consumers.visible
        text: root.tr("What uses the memory")
        font.bold: true
    }

    ConsumerList {
        id: consumers

        Layout.fillWidth: true
        // While the programs can be read the list keeps its room, also before their values arrive.
        visible: root.consumerItems.length > 0 || root.appsAvailable
        items: root.consumerItems
        reserved: root.appsAvailable
        unit: "bytes"
    }
}
