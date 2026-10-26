// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for AppsSource with the real application model of libksysguard, in three phases:
//   1  active, core count unknown: within 5 s there is at least one named row with processes, and no row has a
//      CPU share
//   2  active, core count known: the rows get a CPU share; a row of kind "service" (the session's background
//      services, if the session has any) carries the given services name
//   3  not active: the model is off and the rows are empty
//
// Live scene: needs a running desktop session (the rows come from the session's cgroups).

import QtQuick
import "../../package/contents/ui/data"

Item {
    id: scene

    property bool done: false
    property int phase: 1
    property int serviceRows: 0

    function finish(ok, message) {
        if (scene.done) {
            return;
        }
        scene.done = true;
        console.log(message);
        Qt.exit(ok ? 0 : 1);
    }

    function named(): var {
        return apps.rows.filter(row => row.name !== "" && row.pids.length > 0);
    }

    function describe(): string {
        return "phase=" + scene.phase + " available=" + apps.available + " reading=" + apps.isReading() + " rows=" + JSON.stringify(apps.rows.slice(0, 5));
    }

    function check() {
        if (scene.phase === 1) {
            if (scene.named().length > 0) {
                if (apps.rows.some(row => row.cpu !== null)) {
                    scene.finish(false, "SMOKE FAIL apps: a CPU share without a core count: " + scene.describe());
                    return;
                }
                scene.phase = 2;
            }
        } else if (scene.phase === 2) {
            if (scene.named().length > 0 && apps.rows.every(row => Number.isFinite(row.cpu) && Number.isFinite(row.memory))) {
                const services = apps.rows.filter(row => row.kind === "service");
                if (services.some(row => row.name !== apps.servicesName)) {
                    scene.finish(false, "SMOKE FAIL apps: a service row without the services name: " + scene.describe());
                    return;
                }
                scene.serviceRows = services.length;
                scene.phase = 3;
            }
        } else if (apps.rows.length === 0 && !apps.isReading()) {
            scene.finish(true, "SMOKE OK apps (service rows: " + scene.serviceRows + ")");
        }
    }

    AppsSource {
        id: apps

        active: scene.phase !== 3
        coreCount: scene.phase === 1 ? NaN : 4
        servicesName: "Background services"
    }

    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: scene.check()
    }

    Timer {
        interval: 5000
        running: scene.phase === 1
        onTriggered: scene.finish(false, "SMOKE FAIL apps: no named row within 5 s: " + scene.describe())
    }

    Timer {
        interval: 20000
        running: true
        onTriggered: scene.finish(false, "SMOKE FAIL apps: " + scene.describe())
    }
}
