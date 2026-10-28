// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The panel view: the load rings in a row (horizontal panel) or a column (vertical panel). A click toggles the popup.

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/layout.mjs" as LayoutLogic

Item {
    id: root

    // [{ key: "cpu" | "ram" | "gpu", percent: real }], NaN percent = no value.
    property var rings: []
    // Set by the applet from the form factor. On the desktop the rings are horizontal and sized by the smaller
    // side of the widget. The view reads nothing from Plasmoid, so it also runs in plain qml6.
    property bool vertical: false
    property bool onDesktop: false

    // The keys in order. A string, so that it only notifies when the set of rings changes; a changed percent must
    // not rebuild the ring items.
    readonly property string keyList: root.rings.map(ring => ring.key).join(",")
    readonly property var keys: root.keyList === "" ? [] : root.keyList.split(",")

    // The ring items, for tests.
    readonly property alias ringRepeater: repeater

    // pressed() comes before clicked(): the applet notes the popup state at the press.
    signal pressed
    signal clicked

    // The panel thickness; on the desktop the smaller side.
    readonly property real thickness: root.onDesktop ? Math.min(root.width, root.height) : root.vertical ? root.width : root.height
    readonly property var geometry: LayoutLogic.ringLayout({
        vertical: root.vertical && !root.onDesktop,
        thickness: Number.isFinite(root.thickness) ? root.thickness : 0,
        count: root.keys.length,
        spacing: Kirigami.Units.smallSpacing
    })

    implicitWidth: root.geometry.width
    implicitHeight: root.geometry.height
    Layout.minimumWidth: root.geometry.width
    Layout.minimumHeight: root.geometry.height

    Grid {
        id: grid

        anchors.centerIn: parent
        // One row or one column; a Grid without a count would wrap after four items and set a vertical one in a row.
        columns: root.vertical && !root.onDesktop ? 1 : Math.max(1, root.keys.length)
        spacing: root.geometry.spacing

        Repeater {
            id: repeater

            model: root.keys

            Ring {
                required property int index

                // The keys decide which rings exist, the percents change in place.
                percent: root.rings[index]?.percent ?? NaN
                diameter: root.geometry.diameter
                stroke: root.geometry.stroke
                fontPx: root.geometry.fontPx
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        onPressed: root.pressed()
        onClicked: root.clicked()
    }
}
