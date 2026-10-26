// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for SystemSensors with the real ksystemstats, in three phases:
//   1  not detailed: the CPU and memory values arrive, `current` follows once the heartbeat shows the sensors
//      alive, `cores` is empty (also in `current`); with a GPU in the system the GPU values arrive too
//   2  detailed: there is one entry in `cores` per logical CPU, and `current.cores` has them
//   3  not detailed again: `cores` is empty again
// The GPU is switched on: gpuPending is true at first, while the cards are looked for, and false at the end.
//
// Live scene: needs ksystemstats (the values come from the real sensors).

import QtQuick
import "../../package/contents/ui/data"

Item {
    id: scene

    property bool done: false
    property bool sawTick: false
    // Whether the first check saw the cards still being looked for.
    property bool pendingAtStart: false
    property bool firstCheck: true
    property int phase: 1

    function finish(ok, message) {
        if (scene.done) {
            return;
        }
        scene.done = true;
        console.log(message);
        Qt.exit(ok ? 0 : 1);
    }

    function describe(): string {
        return "cpuUsage=" + sensors.cpuUsage + " memUsedPercent=" + sensors.memUsedPercent + " coreCount=" + sensors.coreCount + " cores=" + sensors.cores.length + " fresh=" + sensors.fresh + " current.cpuUsage=" + sensors.current.cpuUsage + " gpuIds=" + sensors.gpuIds.join("+") + " gpu.usage=" + sensors.gpu.usage;
    }

    function coresComplete(): bool {
        if (!(sensors.coreCount > 0) || sensors.cores.length !== sensors.coreCount) {
            return false;
        }
        return sensors.cores.every(core => Number.isFinite(core.usage));
    }

    function gpuComplete(): bool {
        return sensors.gpuIds.length === 0 || Number.isFinite(sensors.gpu.usage);
    }

    function check() {
        if (scene.firstCheck) {
            scene.firstCheck = false;
            scene.pendingAtStart = sensors.gpuPending;
        }
        if (scene.phase === 1) {
            scene.checkBasics();
        } else if (scene.phase === 2) {
            if (scene.coresComplete() && sensors.current.cores.length === sensors.coreCount) {
                scene.phase = 3;
            }
        } else if (sensors.cores.length === 0 && sensors.current.cores.length === 0) {
            if (scene.pendingAtStart && !sensors.gpuPending) {
                scene.finish(true, "SMOKE OK sensors");
            } else {
                scene.finish(false, "SMOKE FAIL sensors: gpuPending at start " + scene.pendingAtStart + ", at the end " + sensors.gpuPending);
            }
        }
    }

    function checkBasics() {
        const raw = Number.isFinite(sensors.cpuUsage) && Number.isFinite(sensors.memUsedPercent) && scene.gpuComplete();
        const gated = sensors.fresh && Number.isFinite(sensors.current.cpuUsage) && Number.isFinite(sensors.current.memUsedPercent) && scene.sawTick;
        if (raw && gated) {
            if (sensors.cores.length !== 0 || sensors.current.cores.length !== 0) {
                scene.finish(false, "SMOKE FAIL sensors: cores are not empty while not detailed: " + scene.describe());
                return;
            }
            scene.phase = 2;
        }
    }

    SystemSensors {
        id: sensors

        interval: 500
        gpuEnabled: true
        detailed: scene.phase === 2
        onTick: sample => {
            scene.sawTick = Number.isFinite(sample.cpu) && Number.isFinite(sample.ram);
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: true
        onTriggered: scene.check()
    }

    Timer {
        interval: 25000
        running: true
        onTriggered: scene.finish(false, "SMOKE FAIL sensors: " + scene.describe())
    }
}
