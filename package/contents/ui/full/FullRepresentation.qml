// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The popup: one column per device side by side (processor, then memory and the graphics card as they come),
// and a footer with the button for the system monitor and the data source. The view reads nothing from Plasmoid,
// so it also runs in plain qml6 (see tests/qml/PopupSmoke.qml).

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/history.mjs" as History
import "../../code/layout.mjs" as LayoutLogic
import "../../code/popup.mjs" as Popup
import "../../code/text.mjs" as TextTools

Item {
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
    // The load history (history.mjs) and the time window of the graphs in minutes.
    property var history: History.createHistory()
    property int graphMinutes: 5
    // ProcStats.stats (or null) and the context switches per second (NaN when unknown).
    property var stats: null
    property real ctxtPerSecond: NaN
    // HardwareInfo.info, or null.
    property var hardwareInfo: null
    // AppsSource.rows.
    property var appRows: []
    // Whether the popup is open; the graphs only follow the history while it is.
    property bool active: true

    // The user picked another time window.
    signal graphMinutesPicked(int minutes)
    // The button for the system monitor was pressed.
    signal openSystemMonitor

    // The right end of the graphs: never before the newest sample, so it is always drawn.
    readonly property real graphNow: Popup.graphEnd(root.history.times, internals.clock)
    // The points the graphs show; empty while the popup is closed.
    readonly property var graphWindow: root.active ? History.windowOf(root.history, root.graphMinutes, root.graphNow) : internals.emptyWindow

    // Parts for the smoke scenes.
    readonly property CpuColumn cpuColumn: cpu
    readonly property Item footer: footerRow

    Layout.preferredWidth: content.implicitWidth + 2 * content.anchors.margins
    Layout.preferredHeight: content.implicitHeight + 2 * content.anchors.margins
    Layout.minimumWidth: root.Layout.preferredWidth
    Layout.minimumHeight: root.Layout.preferredHeight

    onActiveChanged: internals.clock = Date.now()

    QtObject {
        id: internals

        property real clock: Date.now()
        readonly property var emptyWindow: ({
                times: [],
                cpu: [],
                ram: [],
                gpu: []
            })
    }

    // Lets the graphs scroll on between two samples and through a pause of the sensors.
    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: internals.clock = Date.now()
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        // The columns; memory and the graphics card join here.
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.gridUnit

            CpuColumn {
                id: cpu

                Layout.preferredWidth: LayoutLogic.popupColumnWidth(Kirigami.Units.gridUnit)
                Layout.alignment: Qt.AlignTop
                current: root.current
                fresh: root.fresh
                graphWindow: root.graphWindow
                graphMinutes: root.graphMinutes
                graphNow: root.graphNow
                peakTemperature: root.history.peakCpuTemp
                stats: root.stats
                ctxtPerSecond: root.ctxtPerSecond
                hardwareInfo: root.hardwareInfo
                appRows: root.appRows
                onGraphMinutesPicked: minutes => root.graphMinutesPicked(minutes)
            }
        }

        RowLayout {
            id: footerRow

            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            QQC2.Button {
                text: root.tr("Open System Monitor")
                icon.name: "utilities-system-monitor"
                onClicked: root.openSystemMonitor()
            }

            QQC2.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.tr("Source: system sensors")
                font: Kirigami.Theme.smallFont
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
            }
        }
    }
}
