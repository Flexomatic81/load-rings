// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The graphics cards of the machine for the settings page: `ids` ("gpu0", ...) from the sensor tree and `options`
// ({ text, value } with the name of each card), as the sensors report them. The settings page cannot see
// SystemSensors, so this reads the tree on its own.

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "../../code/sensors.mjs" as SensorCode

Item {
    id: root

    property var ids: []
    // False until the sensor tree has been read once (or the wait for it is over): until then `ids` says nothing.
    property bool scanned: false
    // Card ID to the name its sensor reported.
    property var names: ({})
    readonly property var options: SensorCode.gpuOptions(root.ids, root.names)

    function setName(id: string, name: var): void {
        if (typeof name === "string" && root.names[id] !== name) {
            const next = Object.assign({}, root.names);
            next[id] = name;
            root.names = next;
        }
    }

    // Appends the sensor IDs of all rows below `parent` that are at most `depth` levels deep. Leaves carry an ID,
    // categories and groups do not.
    function collectSensorIds(parent, depth: int, found: var): void {
        const rows = tree.rowCount(parent);
        for (let row = 0; row < rows; row++) {
            const index = tree.index(row, 0, parent);
            const id = tree.data(index, Sensors.SensorTreeModel.SensorId);
            if (typeof id === "string" && id !== "") {
                found.push(id);
            }
            if (depth > 1) {
                root.collectSensorIds(index, depth - 1, found);
            }
        }
    }

    function rescan(): void {
        const found = [];
        // An invalid index stands for the root of the tree.
        const top = tree.index(-1, -1);
        root.collectSensorIds(top, 3, found);
        const cards = SensorCode.gpuIdsFromSensorIds(found);
        if (cards.join("\n") !== root.ids.join("\n")) {
            root.ids = cards;
        }
        // An empty tree means ksystemstats has not answered yet, not that there is no card.
        if (tree.rowCount(top) > 0) {
            root.scanned = true;
        }
    }

    Sensors.SensorTreeModel {
        id: tree
    }

    // The tree fills up and changes in many small steps; the timer merges them.
    Connections {
        target: tree

        function onRowsInserted() {
            rescanTimer.restart();
        }

        function onRowsRemoved() {
            rescanTimer.restart();
        }

        function onModelReset() {
            rescanTimer.restart();
        }
    }

    Timer {
        id: rescanTimer

        interval: 500
        onTriggered: root.rescan()
    }

    // Without ksystemstats the tree stays empty; after this long its emptiness counts as the answer.
    Timer {
        interval: 10000
        running: !root.scanned
        onTriggered: root.scanned = true
    }

    Instantiator {
        model: root.ids

        delegate: Sensors.Sensor {
            id: nameSensor

            required property string modelData

            sensorId: "gpu/" + nameSensor.modelData + "/name"
            onValueChanged: root.setName(nameSensor.modelData, nameSensor.value)
        }
    }

    Component.onCompleted: rescanTimer.restart()
}
