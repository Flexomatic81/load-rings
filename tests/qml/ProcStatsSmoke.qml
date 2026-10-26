// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for ProcStats: nothing runs while inactive; once active it
// delivers a reading and, from the second one, a context switch rate; going
// inactive again forgets the rate. The values depend on the machine, so only
// their types are checked.

import QtQuick
import "../../package/contents/ui/data"

Item {
    id: scene

    property bool done: false
    property int phase: 0

    function finish(ok, message) {
        if (scene.done) {
            return;
        }
        scene.done = true;
        console.log(message);
        Qt.exit(ok ? 0 : 1);
    }

    ProcStats {
        id: procStats

        interval: 300
    }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            if (scene.phase === 0) {
                if (procStats.stats !== null) {
                    scene.finish(false, "SMOKE FAIL procstats: read while inactive");
                } else if (scene.ticks > 5) {
                    procStats.active = true;
                    scene.phase = 1;
                }
                scene.ticks += 1;
            } else if (scene.phase === 1) {
                const s = procStats.stats;
                if (s !== null && !isNaN(procStats.ctxtPerSecond)) {
                    if (s.loadavg === null || s.loadavg.length !== 3 || procStats.ctxtPerSecond < 0) {
                        scene.finish(false, "SMOKE FAIL procstats: bad reading");
                    } else {
                        procStats.active = false;
                        scene.phase = 2;
                    }
                }
            } else if (isNaN(procStats.ctxtPerSecond)) {
                scene.finish(true, "SMOKE OK procstats");
            } else {
                scene.finish(false, "SMOKE FAIL procstats: rate kept after going inactive");
            }
        }
    }

    property int ticks: 0

    Timer {
        interval: 8000
        running: true
        onTriggered: scene.finish(false, "SMOKE FAIL procstats: no result within the time limit")
    }
}
