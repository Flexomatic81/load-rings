// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for ProcStats and HardwareInfo without plasma5support
// (BrokenRunner.qml stands in for the command runner): both load, stay null
// and survive being used. It cannot see QML warnings itself: scripts/smoke.sh
// checks the output of qml6 and allows only the load error of the missing
// module.

import QtQuick
import "../../package/contents/ui/data"

Item {
    id: scene

    function check() {
        const results = [
            procStats.stats === null,
            isNaN(procStats.ctxtPerSecond),
            hardware.info === null,
            hardware.started
        ];
        const bad = results.indexOf(false);
        if (bad >= 0) {
            console.log("SMOKE FAIL no runner: failed check " + bad);
        }
        return bad < 0;
    }

    ProcStats {
        id: procStats

        active: true
        interval: 50
        runnerSource: Qt.resolvedUrl("BrokenRunner.qml")
    }

    HardwareInfo {
        id: hardware

        runnerSource: Qt.resolvedUrl("BrokenRunner.qml")
    }

    Timer {
        // Lets the timer of ProcStats fire a few times first.
        interval: 400
        running: true
        onTriggered: {
            hardware.load();
            if (scene.check()) {
                console.log("SMOKE OK no runner");
                Qt.exit(0);
            } else {
                Qt.exit(1);
            }
        }
    }
}
