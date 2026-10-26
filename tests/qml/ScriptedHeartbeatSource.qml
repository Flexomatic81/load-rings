// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The real SystemSensors with fixed sensor values and a heartbeat the test drives (see HeartbeatSmoke.qml): the
// heartbeat sensor counts as missing, the start-up probe ends after one second, hold() reports one value that
// never changes and every beat() changes the value, which is one sign of life.

import QtQuick
import "../../package/contents/ui/data"

SystemSensors {
    id: root

    heartbeatValue: undefined
    heartbeatSensorReady: false
    heartbeatProbeMs: 1000
    interval: 500
    gpuEnabled: true
    gpuId: "gpu0"
    live: ({
            "cpuUsage": 34,
            "cpuFrequency": 3600,
            "cpuMaxFrequency": 5000,
            "cpuTemperature": 55,
            "coreCount": 2,
            "cores": [
                {
                    "usage": 5,
                    "frequency": 3500,
                    "temperature": 50
                },
                {
                    "usage": 60,
                    "frequency": 3700,
                    "temperature": 56
                }
            ],
            "memTotal": 32e9,
            "memUsed": 18e9,
            "memApplication": 12e9,
            "memUsedPercent": 58,
            "swapTotal": 8e9,
            "swapUsed": 1e9,
            "gpu": {
                "name": "Test GPU",
                "usage": 7,
                "temperature": 61,
                "hotspot": 70,
                "memTemperature": NaN,
                "coreFrequency": 1800,
                "memoryFrequency": 2000,
                "usedVram": 2e9,
                "totalVram": 8e9,
                "power": 90,
                "fan": 1200
            }
        })

    function hold() {
        root.heartbeatValue = 0;
    }

    function beat() {
        root.heartbeatValue = root.heartbeatValue === undefined ? 1 : root.heartbeatValue + 1;
    }
}
