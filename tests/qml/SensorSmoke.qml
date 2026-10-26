// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for SystemSensors with the real ksystemstats: the CPU and memory values arrive, there is one
// entry in `cores` per logical CPU, and `current` follows once the heartbeat shows the sensors alive. With a GPU
// in the system the GPU values arrive too.
//
// Live scene: needs ksystemstats (the values come from the real sensors).

import QtQuick
import "../../package/contents/ui/data"

Item {
    id: scene

    property bool done: false
    property bool sawTick: false

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
        const raw = Number.isFinite(sensors.cpuUsage) && Number.isFinite(sensors.memUsedPercent) && scene.coresComplete() && scene.gpuComplete();
        const gated = sensors.fresh && Number.isFinite(sensors.current.cpuUsage) && Number.isFinite(sensors.current.memUsedPercent) && scene.sawTick;
        if (raw && gated) {
            scene.finish(true, "SMOKE OK sensors");
        }
    }

    SystemSensors {
        id: sensors

        interval: 500
        gpuEnabled: true
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
