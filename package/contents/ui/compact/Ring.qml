// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// One load ring: a dim track, an arc from 12 o'clock clockwise in the load color, and the rounded percentage in
// the middle ("34%"). A ring without a value (NaN) shows the track and a dash. Drawn like the gauges of the sibling
// widgets: the line runs a little inside the edge with flat ends, so 0 % shows no arc.

import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "../../code/color.mjs" as ColorTools
import "../../code/format.mjs" as Format
import "../../code/layout.mjs" as LayoutLogic

Item {
    id: root

    // NaN means no value.
    property real percent: NaN
    property real diameter: 24
    property real stroke: LayoutLogic.RING_STROKE_PX
    property int fontPx: 10

    readonly property color arcColor: ColorTools.ringColor(root.percent) ?? "transparent"
    readonly property real sweep: Number.isFinite(root.percent) ? Math.min(100, Math.max(0, root.percent)) * 3.6 : 0
    // An arc is drawn only for a load above 0 %.
    readonly property bool hasArc: root.sweep > 0
    readonly property real radius: root.diameter / 2 - LayoutLogic.RING_INSET_PX
    readonly property string text: Format.ringLabel(root.percent)

    // The label, for tests.
    readonly property alias label: label

    implicitWidth: root.diameter
    implicitHeight: root.diameter

    Shape {
        id: shape

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.2)
            strokeWidth: root.stroke
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.hasArc ? root.arcColor : "transparent"
            strokeWidth: root.stroke
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: -90
                sweepAngle: root.sweep
            }
        }
    }

    // The font size is measured on the widest two-digit label. With tabular figures every two-digit number is as wide
    // as "00%", so one and two digits share one size and the numbers do not change size with the load.
    TextMetrics {
        id: twoDigits

        font.family: label.font.family
        font.pixelSize: root.fontPx
        font.features: {
            "tnum": 1
        }
        text: "00%"
    }

    PlasmaComponents.Label {
        id: label

        // The label keeps 2 px of air on each side inside the line.
        readonly property real room: Math.max(0, 2 * (root.radius - root.stroke) - 4)

        anchors.centerIn: parent
        width: label.room
        horizontalAlignment: Text.AlignHCenter
        // Only the rare "100%" is wider than two digits; it alone shrinks to fit.
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 6
        text: root.text
        color: Kirigami.Theme.textColor
        font.pixelSize: Math.max(6, twoDigits.advanceWidth > label.room ? Math.floor(root.fontPx * label.room / twoDigits.advanceWidth) : root.fontPx)
        font.features: {
            "tnum": 1
        }
    }
}
