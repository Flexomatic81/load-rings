// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// One load ring: a dim track, an arc from 12 o'clock clockwise in the load color, and the rounded percentage in
// the middle. A ring without a value (NaN) shows the track and a dash.

import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import "../../code/color.mjs" as ColorTools
import "../../code/format.mjs" as Format

Item {
    id: root

    // NaN means no value.
    property real percent: NaN
    property real diameter: 24
    property real stroke: 3
    property int fontPx: 8

    readonly property color arcColor: ColorTools.ringColor(root.percent) ?? "transparent"
    readonly property bool hasArc: ColorTools.ringColor(root.percent) !== null
    readonly property real sweep: Math.min(100, Math.max(0, root.percent)) * 3.6
    readonly property string text: Format.ringText(root.percent)

    implicitWidth: root.diameter
    implicitHeight: root.diameter

    Shape {
        id: shape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.15)
            strokeWidth: root.stroke
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.diameter - root.stroke) / 2
                radiusY: (root.diameter - root.stroke) / 2
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.hasArc ? root.arcColor : "transparent"
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.diameter - root.stroke) / 2
                radiusY: (root.diameter - root.stroke) / 2
                startAngle: -90
                sweepAngle: root.hasArc ? Math.max(0.1, root.sweep) : 0
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.text
        color: Kirigami.Theme.textColor
        font.pixelSize: root.fontPx
        font.features: {
            "tnum": 1
        }
    }
}
