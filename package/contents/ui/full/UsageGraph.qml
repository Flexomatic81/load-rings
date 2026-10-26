// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// A usage graph on a fixed 0-100 % axis: a filled line over the last `minutes` minutes before `now`, with grid
// lines at 25, 50 and 75 %. A null value breaks the line (a gap).

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import "../../code/history.mjs" as History

Item {
    id: root

    // Time of each point in ms, and its value (0-100 or null).
    property var times: []
    property var values: []
    property color color: Kirigami.Theme.highlightColor
    // The span shown, in minutes, ending at `now` (ms).
    property real minutes: 5
    property real now: 0

    readonly property var paths: History.graphPaths(root.times, root.values, {
            minutes: root.minutes,
            now: root.now,
            width: root.width,
            height: root.height
        })

    implicitHeight: Kirigami.Units.gridUnit * 4

    Repeater {
        model: [25, 50, 75]

        Rectangle {
            id: gridLine

            required property int modelData

            width: root.width
            height: 1
            y: root.height - (gridLine.modelData / 100) * root.height
            color: Kirigami.Theme.textColor
            opacity: 0.15
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.14)

            PathSvg {
                path: root.paths.fill
            }
        }

        ShapePath {
            strokeWidth: 1.5
            strokeColor: root.color
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            PathSvg {
                path: root.paths.line
            }
        }
    }
}
