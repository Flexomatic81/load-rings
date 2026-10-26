// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The panel view: the load rings in a row (horizontal panel) or a column (vertical panel). A click toggles the popup.

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../code/layout.mjs" as LayoutLogic

Item {
    id: root

    // [{ key: "cpu" | "ram" | "gpu", percent: real }], NaN percent = no value.
    property var rings: []
    // Set by the applet from the form factor. On the desktop the rings are horizontal and sized by the smaller
    // side of the widget. The view reads nothing from Plasmoid, so it also runs in plain qml6.
    property bool vertical: false
    property bool onDesktop: false

    // The ring items, for tests.
    readonly property alias ringRepeater: repeater

    signal clicked

    // The panel thickness; on the desktop the smaller side.
    readonly property real thickness: root.onDesktop ? Math.min(root.width, root.height) : root.vertical ? root.width : root.height
    readonly property var geometry: LayoutLogic.ringLayout({
        vertical: root.vertical && !root.onDesktop,
        thickness: Number.isFinite(root.thickness) ? root.thickness : 0,
        count: root.rings.length
    })

    implicitWidth: root.geometry.width
    implicitHeight: root.geometry.height
    Layout.minimumWidth: root.geometry.width
    Layout.minimumHeight: root.geometry.height

    Grid {
        id: grid

        anchors.centerIn: parent
        flow: root.vertical && !root.onDesktop ? Grid.TopToBottom : Grid.LeftToRight
        spacing: root.geometry.spacing

        Repeater {
            id: repeater

            model: root.rings

            Ring {
                required property var modelData

                percent: modelData.percent
                diameter: root.geometry.diameter
                stroke: root.geometry.stroke
                fontPx: root.geometry.fontPx
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        onClicked: root.clicked()
    }
}
