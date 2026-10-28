// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The sensor values of the machine from ksystemstats. Unknown values are NaN. Everything that is shown reads
// `current`, which is NaN throughout while ksystemstats looks stalled (see the heartbeat check in sensors.mjs);
// the raw properties are for tests.

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "../../code/sensors.mjs" as SensorCode

Item {
    id: root

    // Sampling interval in milliseconds.
    property int interval: 2000
    // Whether the per-core values are read (only needed while the popup is open). While not, `cores` is empty.
    property bool detailed: false
    property bool gpuEnabled: false
    // The wanted GPU ("gpu0"); the first one is used when it is empty or missing.
    property string gpuWanted: ""

    // Test seams: the sign of life, whether its sensor exists, and how long the start-up probe waits before it
    // decides that the sensor is missing. Bound to the heartbeat sensor below; tests replace them.
    property var heartbeatValue: heartbeat.value
    property bool heartbeatSensorReady: heartbeat.status === Sensors.Sensor.Ready
    property int heartbeatProbeMs: 10000

    // False while the heartbeat is missing or too old.
    property bool fresh: false

    // Raw values.
    readonly property real cpuUsage: root.num(cpuUsageSensor.value)
    readonly property real cpuFrequency: root.num(cpuFrequencySensor.value)
    readonly property real cpuTemperature: root.detailed && Number.isNaN(root.num(cpuTemperatureSensor.value)) ? SensorCode.maxFinite(root.cores.map(core => core.temperature)) : root.num(cpuTemperatureSensor.value)
    readonly property real coreCount: root.num(coreCountSensor.value)
    // [{ usage, frequency, temperature }], one per logical CPU.
    property var cores: []
    readonly property real memTotal: root.num(memTotalSensor.value)
    readonly property real memUsed: root.num(memUsedSensor.value)
    readonly property real memApplication: root.num(memApplicationSensor.value)
    readonly property real memUsedPercent: root.num(memPercentSensor.value)
    readonly property real swapTotal: root.num(swapTotalSensor.value)
    readonly property real swapUsed: root.num(swapUsedSensor.value)
    // The GPUs ksystemstats offers ("gpu0", ...) and the chosen one ("" when none or not shown).
    property var gpuIds: cards.ids
    // Writable only as a test seam.
    property string gpuId: SensorCode.chosenGpu(root.gpuEnabled, root.gpuIds, root.gpuWanted)
    // True while the GPU is switched on but the cards are still looked for: gpuId says nothing yet.
    readonly property bool gpuPending: root.gpuEnabled && !cards.scanned
    readonly property var gpu: ({
            "name": typeof gpuNameSensor.value === "string" ? gpuNameSensor.value : "",
            "usage": root.num(gpuUsageSensor.value),
            "temperature": root.num(gpuTemperatureSensor.value),
            "hotspot": root.num(gpuHotspotSensor.value),
            "memTemperature": root.num(gpuMemTemperatureSensor.value),
            "coreFrequency": root.num(gpuCoreFrequencySensor.value),
            "memoryFrequency": root.num(gpuMemoryFrequencySensor.value),
            "usedVram": root.num(gpuUsedVramSensor.value),
            "totalVram": root.num(gpuTotalVramSensor.value),
            "power": root.num(gpuPowerSensor.value),
            "fan": root.num(gpuFanSensor.value)
        })

    // The snapshot that is shown: the raw values, or the same shape with NaN everywhere when not fresh.
    readonly property var current: root.fresh ? root.live : SensorCode.blankNumbers(root.live)
    // The raw values as one snapshot. Writable only as a test seam: tests replace it with fixed values.
    property var live: ({
        "cpuUsage": root.cpuUsage,
        "cpuFrequency": root.cpuFrequency,
        "cpuTemperature": root.cpuTemperature,
        "coreCount": root.coreCount,
        "cores": root.cores,
        "memTotal": root.memTotal,
        "memUsed": root.memUsed,
        "memApplication": root.memApplication,
        "memUsedPercent": root.memUsedPercent,
        "swapTotal": root.swapTotal,
        "swapUsed": root.swapUsed,
        "gpu": root.gpu
    })

    // One sample per interval while fresh: { timestamp, intervalMs, cpu, ram, gpu, gpuId, cpuTemp, gpuTemp }.
    signal tick(var sample)

    // A sensor value as a number; NaN until it has been read.
    function num(value): real {
        return SensorCode.cleanValue(value) ?? NaN;
    }

    function sensorFor(ids, field: string): string {
        return root.gpuId === "" ? "" : ids[field];
    }

    QtObject {
        id: internals

        readonly property var gpuSensors: SensorCode.gpuSensorIds(root.gpuId === "" ? "gpu0" : root.gpuId)
        // Whether samples need a fresh heartbeat, and when the last one came; see heartbeatGate() in sensors.mjs.
        property var gate: SensorCode.initialHeartbeatGate()

        // Applies a heartbeat event, logs when the check goes off or on, and updates `fresh`.
        function updateGate(event) {
            const next = SensorCode.heartbeatGate(internals.gate, event);
            if (next.required !== internals.gate.required) {
                console.warn("loadrings: heartbeat sensor " + SensorCode.HEARTBEAT_SENSOR + (next.required ? " is back, staleness check enabled" : " unavailable, staleness check disabled"));
            }
            internals.gate = next;
            internals.refreshFresh();
        }

        function refreshFresh() {
            root.fresh = SensorCode.heartbeatAllows(internals.gate, Date.now(), root.interval);
        }

        // objectAt() is typed QObject; the properties of the delegate are only known at runtime.
        function coreAt(index): var {
            return coreInstances.objectAt(index);
        }

        function rebuildCores() {
            const list = [];
            for (let i = 0; i < coreInstances.count; i++) {
                const core = internals.coreAt(i);
                list.push(core === null ? {
                    "usage": NaN,
                    "frequency": NaN,
                    "temperature": NaN
                } : core.snapshot);
            }
            root.cores = list;
        }
    }

    // The core sensors exist only while `detailed`; the count of CPU threads decides how many.
    Instantiator {
        id: coreInstances

        model: root.detailed && Number.isFinite(root.coreCount) ? root.coreCount : 0
        onObjectAdded: coreTimer.restart()
        onObjectRemoved: coreTimer.restart()

        delegate: QtObject {
            id: core

            required property int index
            readonly property var ids: SensorCode.coreSensorIds(core.index)
            readonly property var snapshot: ({
                    "usage": root.num(usageSensor.value),
                    "frequency": root.num(frequencySensor.value),
                    "temperature": root.num(temperatureSensor.value)
                })
            onSnapshotChanged: coreTimer.restart()

            property Sensors.Sensor usageSensor: Sensors.Sensor {
                sensorId: core.ids.usage
                updateRateLimit: root.interval
            }
            property Sensors.Sensor frequencySensor: Sensors.Sensor {
                sensorId: core.ids.frequency
                updateRateLimit: root.interval
            }
            property Sensors.Sensor temperatureSensor: Sensors.Sensor {
                sensorId: core.ids.temperature
                updateRateLimit: root.interval
            }
        }
    }

    // The core sensors report in many small steps; the timer merges them into one list.
    Timer {
        id: coreTimer

        interval: 50
        onTriggered: internals.rebuildCores()
    }

    Sensors.Sensor {
        id: cpuUsageSensor

        sensorId: "cpu/all/usage"
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: cpuFrequencySensor

        sensorId: "cpu/all/averageFrequency"
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: cpuTemperatureSensor

        sensorId: "cpu/all/averageTemperature"
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: coreCountSensor

        sensorId: "cpu/all/coreCount"
        updateRateLimit: 10000
    }
    Sensors.Sensor {
        id: memTotalSensor

        sensorId: "memory/physical/total"
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: memUsedSensor

        sensorId: "memory/physical/used"
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: memApplicationSensor

        sensorId: "memory/physical/application"
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: memPercentSensor

        sensorId: "memory/physical/usedPercent"
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: swapTotalSensor

        sensorId: "memory/swap/total"
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: swapUsedSensor

        sensorId: "memory/swap/used"
        updateRateLimit: root.interval
    }

    // The GPU sensors have an empty ID (and so no subscription) while no GPU is shown.
    Sensors.Sensor {
        id: gpuNameSensor

        sensorId: root.sensorFor(internals.gpuSensors, "name")
    }
    Sensors.Sensor {
        id: gpuUsageSensor

        sensorId: root.sensorFor(internals.gpuSensors, "usage")
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: gpuTemperatureSensor

        sensorId: root.sensorFor(internals.gpuSensors, "temperature")
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: gpuHotspotSensor

        sensorId: root.sensorFor(internals.gpuSensors, "temp2")
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: gpuMemTemperatureSensor

        sensorId: root.sensorFor(internals.gpuSensors, "temp3")
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: gpuCoreFrequencySensor

        sensorId: root.sensorFor(internals.gpuSensors, "coreFrequency")
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: gpuMemoryFrequencySensor

        sensorId: root.sensorFor(internals.gpuSensors, "memoryFrequency")
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: gpuUsedVramSensor

        sensorId: root.sensorFor(internals.gpuSensors, "usedVram")
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: gpuTotalVramSensor

        sensorId: root.sensorFor(internals.gpuSensors, "totalVram")
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: gpuPowerSensor

        sensorId: root.sensorFor(internals.gpuSensors, "power")
        updateRateLimit: root.interval
    }
    Sensors.Sensor {
        id: gpuFanSensor

        sensorId: root.sensorFor(internals.gpuSensors, "fan1")
        updateRateLimit: root.interval
    }

    // The graphics cards in the sensor tree.
    GpuChoices {
        id: cards
    }

    // libksysguard does not repeat unchanged values, so a stalled ksystemstats cannot be told from steady
    // values. The system uptime changes every second and serves as the sign of life.
    Sensors.Sensor {
        id: heartbeat

        sensorId: SensorCode.HEARTBEAT_SENSOR
        updateRateLimit: 1000
    }

    // The sensor also signals once on creation, before it has a value.
    onHeartbeatValueChanged: {
        if (root.heartbeatValue !== undefined) {
            internals.updateGate({
                "type": "heartbeat",
                "now": Date.now(),
                "value": root.heartbeatValue
            });
        }
    }

    // Without a heartbeat sensor (missing in this Plasma version, or ksystemstats not running yet) the check
    // would block everything, so it is switched off until a heartbeat arrives.
    Timer {
        interval: root.heartbeatProbeMs
        running: true
        onTriggered: internals.updateGate({
            "type": "probe-expired",
            "sensorReady": root.heartbeatSensorReady
        })
    }

    // Re-checks the heartbeat age (it only changes when the heartbeat stops) and hands out the sample.
    Timer {
        interval: root.interval
        repeat: true
        running: true
        onTriggered: {
            internals.refreshFresh();
            if (root.fresh) {
                root.tick(SensorCode.tickSample(Date.now(), root.interval, root.current, root.gpuId === "" ? null : root.gpuId));
            }
        }
    }

}
