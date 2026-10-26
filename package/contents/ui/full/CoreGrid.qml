// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The logical CPUs as a grid of small upright bars in the load colour. With few columns each bar has its number
// above and its load below; with many only the bar fits. Hovering a bar shows its core, load, temperature and clock.

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../../code/color.mjs" as Color
import "../../code/format.mjs" as Format
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

    // [{ usage, frequency, temperature }], one per logical CPU. May be empty.
    property var cores: []
    // The number of logical CPUs as far as it is known before their values (0 otherwise). The grid lays out that
    // many cells at once, so it does not grow when the values arrive; a cell without its value shows the dash.
    property int count: 0

    // The cells laid out.
    readonly property int cellCount: Math.max(root.cores.length, root.count)
    readonly property int columns: LayoutLogic.coreGridColumns(root.cellCount)
    readonly property real cellSpacing: 2
    // The cells share the width the grid gets.
    readonly property real cellWidth: Math.max(1, (root.width - (root.columns - 1) * root.cellSpacing) / root.columns)
    // Numbers only where they fit.
    readonly property bool labelled: root.columns <= 16
    // The width the cells take (for the smoke scene).
    readonly property real contentWidth: grid.width
    // The cells, for tests.
    readonly property alias cellRepeater: repeater

    readonly property var translator: ({
            tr: root.tr,
            trc: root.trc,
            trp: root.trp
        })

    implicitWidth: LayoutLogic.popupColumnWidth(Kirigami.Units.gridUnit)
    implicitHeight: grid.height

    Grid {
        id: grid

        columns: root.columns
        spacing: root.cellSpacing

        Repeater {
            id: repeater

            // The count, not the list: new values must not rebuild the cells.
            model: root.cellCount

            Column {
                id: cell

                required property int index
                // The values may be missing for a moment while the list is rebuilt.
                readonly property var core: root.cores[cell.index] ?? null
                readonly property real usage: cell.core === null ? NaN : cell.core.usage
                readonly property string valueText: Format.ringText(cell.usage)

                width: root.cellWidth
                spacing: 1

                QQC2.Label {
                    width: cell.width
                    visible: root.labelled
                    text: String(cell.index + 1)
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.features: { "tnum": 1 }
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 6
                    color: Kirigami.Theme.disabledTextColor
                }

                Rectangle {
                    id: track

                    width: cell.width
                    height: Math.round(Kirigami.Units.gridUnit * 1.2)
                    radius: 2
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

                    Rectangle {
                        anchors.bottom: track.bottom
                        width: track.width
                        height: track.height * Popup.barFraction(cell.usage / 100)
                        radius: track.radius
                        color: Color.ringColor(cell.usage) ?? "transparent"
                    }
                }

                QQC2.Label {
                    width: cell.width
                    visible: root.labelled
                    text: cell.valueText
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.features: { "tnum": 1 }
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 6
                }

                HoverHandler {
                    id: hover
                }

                QQC2.ToolTip.visible: hover.hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                QQC2.ToolTip.text: hover.hovered ? Popup.coreTooltip(cell.index, cell.core, root.translator, Qt.locale().decimalPoint) : ""
            }
        }
    }
}
