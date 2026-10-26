// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for HardwareInfo: info is null until load() is called, load()
// runs the query once, and the result has the parsed shape. The values
// depend on the machine, so only their types are checked.

import QtQuick
import "../../package/contents/ui/data"

Item {
    id: scene

    property bool done: false

    function finish(ok, message) {
        if (scene.done) {
            return;
        }
        scene.done = true;
        console.log(message);
        Qt.exit(ok ? 0 : 1);
    }

    function fail(message) {
        scene.finish(false, "SMOKE FAIL hardware: " + message);
    }

    function judge() {
        const info = hardware.info;
        if (info === null) {
            scene.fail("no result within the time limit");
        } else if (info.cpuModel !== null && typeof info.cpuModel !== "string") {
            scene.fail("cpuModel is not a string");
        } else if (info.memory !== null && info.memory.modules.length === 0) {
            scene.fail("memory without modules");
        } else {
            scene.finish(true, "SMOKE OK hardware");
        }
    }

    HardwareInfo {
        id: hardware
    }

    Timer {
        id: poll

        interval: 100
        repeat: true
        running: false
        onTriggered: {
            if (hardware.info !== null) {
                poll.stop();
                limit.stop();
                scene.judge();
            }
        }
    }

    Timer {
        id: limit

        interval: 8000
        onTriggered: {
            poll.stop();
            scene.judge();
        }
    }

    Component.onCompleted: {
        if (hardware.info !== null || hardware.started) {
            scene.fail("not idle before load()");
            return;
        }
        hardware.load();
        hardware.load();
        poll.start();
        limit.start();
    }
}
