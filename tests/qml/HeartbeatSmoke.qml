// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for the freshness check of SystemSensors: fixed sensor values and a heartbeat the scene drives
// (ScriptedHeartbeatSource.qml), with the rings the applet builds from `current` and the popup fed from it, in
// four steps:
//   1  no heartbeat yet: not fresh, every ring and the processor figures of the popup (usage, clock, temperature,
//      core grid) and the memory figures (used, percent, swap) show the dash, `current` is NaN throughout (the lists keep their length, the GPU name stays),
//      no tick; the graphics card figures (usage, clock, temperature, power) show the dash too, and a switch to
//      another card empties the graph and drops the peak at once, although nothing is fresh
//   2  the heartbeat starts: fresh, the rings show the numbers, `current` has the values, ticks arrive
//   3  the heartbeat stops: after the heartbeat window not fresh again, same picture as in step 1, and the
//      ticks stop
//   4  the heartbeat comes back: fresh again, the numbers are back

import QtQuick
import "../../package/contents/ui/compact"
import "../../package/contents/ui/full"
import "../../package/contents/code/history.mjs" as HistoryCode
import "../../package/contents/code/sensors.mjs" as SensorCode

Item {
    id: scene

    width: 600
    height: 900

    readonly property int intervalMs: 500
    readonly property int windowMs: SensorCode.heartbeatWindowMs(scene.intervalMs)
    readonly property int stepTimeoutMs: 6000
    // Timer jitter allowed around the expected moments.
    readonly property int slackMs: 150

    property int step: 0
    property double stepStart: 0
    property double lastBeatAt: 0
    property bool beating: false
    property int ticks: 0
    property int ticksAtStale: 0
    property var firstSample: null
    // The load history the popup shows: one old sample of "gpu0" with a peak, and it follows the card like the
    // applet's history does.
    property var history: HistoryCode.pushSample(HistoryCode.createHistory(), {
        "timestamp": Date.now() - 1000,
        "intervalMs": 500,
        "cpu": 1,
        "ram": 1,
        "gpu": 5,
        "gpuId": "gpu0",
        "cpuTemp": 50,
        "gpuTemp": 74
    })
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
        scene.finish(false, "SMOKE FAIL heartbeat: step " + scene.step + ": " + message);
    }

    function enter(step) {
        scene.step = step;
        scene.stepStart = Date.now();
        console.log("heartbeat: step " + step);
    }

    function beat() {
        scene.lastBeatAt = Date.now();
        sensors.beat();
    }

    // Untyped on purpose: the repeater hands out plain items.
    function ringAt(index): var {
        return view.ringRepeater.itemAt(index);
    }

    function texts(): string {
        let list = [];
        for (let i = 0; i < view.ringRepeater.count; i++) {
            list.push(scene.ringAt(i).text);
        }
        return list.join(",");
    }

    // "" when `current` is blank throughout, else what is wrong.
    function blankProblem(): string {
        const now = sensors.current;
        const checks = {
            "cpuUsage": Number.isNaN(now.cpuUsage),
            "memUsedPercent": Number.isNaN(now.memUsedPercent),
            "coreCount": Number.isNaN(now.coreCount),
            "cores length": now.cores.length === 2,
            "cores[0].usage": Number.isNaN(now.cores[0].usage),
            "gpu.usage": Number.isNaN(now.gpu.usage),
            "gpu.name": now.gpu.name === "Test GPU",
            "dashes": scene.texts() === "–,–,–",
            "popup dashes": scene.popupTexts() === "–|–|–|–,–",
            "memory dashes": scene.memoryTexts() === "–|–|–",
            "gpu dashes": scene.gpuTexts() === "–|–|–|–"
        };
        return scene.failedNames(checks);
    }

    // "" when `current` holds the fixed values, else what is wrong.
    function valuesProblem(): string {
        const now = sensors.current;
        const checks = {
            "cpuUsage": now.cpuUsage === 34,
            "memUsedPercent": now.memUsedPercent === 58,
            "cores[1].usage": now.cores[1].usage === 60,
            "gpu.usage": now.gpu.usage === 7,
            "gpu.name": now.gpu.name === "Test GPU",
            "numbers": scene.texts() === "34,58,7",
            "popup numbers": scene.popupTexts() === "34 %|" + (3.6).toFixed(2).replace(".", Qt.locale().decimalPoint) + "|55 °C|5,60",
            "gpu numbers": scene.gpuTexts() === ["7 %", (1.8).toFixed(2).replace(".", Qt.locale().decimalPoint), "61 °C", "90 W"].join("|"),
            "memory numbers": scene.memoryTexts() === ["16.8 of 29.8 GiB used", "58 %", "954 MiB of 7.5 GiB"].map(text => text.replace(/\./g, Qt.locale().decimalPoint)).join("|")
        };
        return scene.failedNames(checks);
    }

    // Untyped on purpose: the repeater hands out plain items.
    function coreAt(index): var {
        return popup.cpuColumn.coreGrid.cellRepeater.itemAt(index);
    }

    // "usage|clock|temperature|core values" as the popup shows them; the clock and temperature tiles must be
    // visible.
    function popupTexts(): string {
        const cpu = popup.cpuColumn;
        if (!cpu.clockTile.visible || !cpu.temperatureTile.visible) {
            return "hidden tile";
        }
        const cores = [];
        for (let i = 0; i < cpu.coreGrid.cellRepeater.count; i++) {
            cores.push(scene.coreAt(i).valueText);
        }
        return [cpu.usageTile.value, cpu.clockTile.value, cpu.temperatureTile.value, cores.join(",")].join("|");
    }

    // "used|percent|swap" as the memory column shows them; the used line and the swap row must be visible.
    function memoryTexts(): string {
        const ram = popup.ramColumn;
        if (!ram.usedLabel.visible || !ram.swapRow.visible) {
            return "hidden";
        }
        return [ram.usedLabel.text, ram.percentLabel.text, ram.swapRow.text].join("|");
    }

    // "usage|clock|temperature|power" as the graphics card column shows them; all four tiles must be visible.
    function gpuTexts(): string {
        const gpu = popup.gpuColumn;
        if (!gpu.visible || !gpu.clockTile.visible || !gpu.temperatureTile.visible || !gpu.powerTile.visible) {
            return "hidden";
        }
        return [gpu.usageTile.value, gpu.clockTile.value, gpu.temperatureTile.value, gpu.powerTile.value].join("|");
    }

    // Whether a graph window has no GPU value (a point of another card is kept as a gap).
    function noGpuValues(window: var): bool {
        return window.gpu.every(value => value === null);
    }

    // The history of "gpu0" is shown with its peak; then the card changes while nothing is fresh: the graph of the
    // new card is empty and has no peak at once. Back on "gpu0" the history stays empty (it was cleared).
    // "" when all of that holds, else what is wrong.
    function switchProblem(): string {
        const gpu = popup.gpuColumn;
        const before = gpu.graphWindow.gpu.join(",") === "5" && gpu.temperatureTile.detail === "Peak 74 °C";
        sensors.gpuId = "gpu1";
        const switched = scene.noGpuValues(gpu.graphWindow) && gpu.temperatureTile.detail === "" && gpu.nameLabel.text === "Test GPU";
        sensors.gpuId = "gpu0";
        const back = scene.noGpuValues(gpu.graphWindow) && gpu.temperatureTile.detail === "";
        return scene.failedNames({
            "history of the first card": before,
            "empty at once for the new card": switched,
            "empty after switching back": back
        });
    }

    function failedNames(checks): string {
        return Object.keys(checks).filter(name => !checks[name]).join(", ");
    }

    function tickProblem(sample): string {
        const ok = sample.cpu === 34 && sample.ram === 58 && sample.gpu === 7 && sample.gpuId === "gpu0" && sample.cpuTemp === 55 && sample.gpuTemp === 61 && sample.intervalMs === scene.intervalMs && sample.timestamp > 0;
        return ok ? "" : JSON.stringify(sample);
    }

    // Step 1: checked at once, the heartbeat starts afterwards.
    function stepWaiting() {
        const problem = scene.blankProblem() + scene.switchProblem();
        if (sensors.fresh || problem !== "" || scene.ticks !== 0) {
            scene.fail("before the first heartbeat: fresh=" + sensors.fresh + " ticks=" + scene.ticks + " wrong: " + problem);
            return;
        }
        scene.enter(2);
        scene.beating = true;
        scene.beat();
    }

    function stepBeating(now) {
        if (sensors.fresh && scene.valuesProblem() === "" && scene.ticks > 0) {
            const wrong = scene.tickProblem(scene.firstSample);
            if (wrong !== "") {
                scene.fail("tick sample: " + wrong);
                return;
            }
            scene.enter(3);
            scene.beating = false;
        } else if (now - scene.stepStart > scene.stepTimeoutMs) {
            scene.fail("not fresh with the numbers after the heartbeat started: fresh=" + sensors.fresh + " ticks=" + scene.ticks + " wrong: " + scene.valuesProblem());
        }
    }

    function stepStopped(now) {
        const sinceBeat = now - scene.lastBeatAt;
        if (sensors.fresh) {
            if (sinceBeat > scene.windowMs + scene.intervalMs + 2 * scene.slackMs) {
                scene.fail("still fresh " + sinceBeat + " ms after the last heartbeat");
            }
            return;
        }
        if (sinceBeat < scene.windowMs - scene.slackMs) {
            scene.fail("not fresh " + sinceBeat + " ms after the last heartbeat, before the " + scene.windowMs + " ms window ran out");
            return;
        }
        const problem = scene.blankProblem();
        if (problem !== "") {
            scene.fail("not fresh but not blank: " + problem);
            return;
        }
        scene.ticksAtStale = scene.ticks;
        scene.enter(31);
    }

    // Step 3b: no tick while not fresh.
    function stepQuiet(now) {
        if (scene.ticks !== scene.ticksAtStale) {
            scene.fail("a tick arrived while not fresh");
        } else if (now - scene.stepStart > 2 * scene.intervalMs + scene.slackMs) {
            scene.enter(4);
            scene.beating = true;
            scene.beat();
        }
    }

    function stepReturned(now) {
        if (sensors.fresh && scene.valuesProblem() === "") {
            scene.finish(true, "SMOKE OK heartbeat");
        } else if (now - scene.stepStart > scene.stepTimeoutMs) {
            scene.fail("not fresh with the numbers after the heartbeat came back: fresh=" + sensors.fresh + " wrong: " + scene.valuesProblem());
        }
    }

    function tick() {
        if (scene.done) {
            return;
        }
        const now = Date.now();
        switch (scene.step) {
        case 0:
            scene.enter(1);
            break;
        case 1:
            scene.stepWaiting();
            break;
        case 2:
            scene.stepBeating(now);
            break;
        case 3:
            scene.stepStopped(now);
            break;
        case 31:
            scene.stepQuiet(now);
            break;
        case 4:
            scene.stepReturned(now);
            break;
        }
    }

    ScriptedHeartbeatSource {
        id: sensors

        onTick: sample => {
            if (scene.firstSample === null) {
                scene.firstSample = sample;
            }
            scene.ticks += 1;
        }
    }

    CompactRepresentation {
        id: view

        width: 300
        height: 44
        // The same function the applet uses.
        rings: SensorCode.ringValues(sensors.current, sensors.gpuId !== "")
    }

    FullRepresentation {
        id: popup

        y: 100
        current: sensors.current
        fresh: sensors.fresh
        history: scene.history
        gpuId: sensors.gpuId
    }

    Connections {
        target: sensors

        function onGpuIdChanged(): void {
            scene.history = HistoryCode.selectGpu(scene.history, sensors.gpuId === "" ? null : sensors.gpuId);
        }

        function onTick(sample: var): void {
            scene.history = HistoryCode.pushSample(scene.history, sample);
        }
    }

    Timer {
        interval: scene.intervalMs
        repeat: true
        running: scene.beating
        onTriggered: scene.beat()
    }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: scene.tick()
    }

    Timer {
        interval: 30000
        running: true
        onTriggered: scene.fail("overall timeout after 30 s")
    }
}
