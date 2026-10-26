// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for the popup: one view with every value set, one with every optional value missing (no
// temperature, no clock, no kernel statistics, no hardware info, no programs, no cores). The first shows all
// figures; in the second the temperature, clock and load tiles, the core grid, the details and the program list
// are hidden and the header shows only "CPU". In the memory column the first shows the figures, the bar whose
// segments add up to its width, swap, ZRAM, pressure and the program list; in the second the swap, ZRAM and
// pressure rows, the figures and the program list are hidden and the header shows only the total. The footer button reports
// through its signal. The graphics card column exists only for a GPU that is switched on and found (two columns
// otherwise); with all values it shows the figures, the graph, the video memory and the details, with none the
// optional parts are hidden, and the history of another card gives an empty graph and no peak.

import QtQuick
import QtQuick.Layouts
import "../../package/contents/ui/full"
import "../../package/contents/code/sensors.mjs" as SensorCode

Item {
    id: scene

    width: 1000
    height: 1400

    readonly property double now: Date.now()
    property int monitorOpened: 0

    readonly property var fullCurrent: ({
            "cpuUsage": 34,
            "cpuFrequency": 4120,
            "cpuMaxFrequency": 4550,
            "cpuTemperature": 63,
            "coreCount": 16,
            "cores": Array.from({
                length: 16
            }, (_, i) => ({
                        "usage": i * 6,
                        "frequency": 4000 + i,
                        "temperature": 60 + i
                    })),
            "memTotal": 32e9,
            "memUsed": 18e9,
            "memApplication": 12e9,
            "memUsedPercent": 58,
            "swapTotal": 8e9,
            "swapUsed": 1e9,
            "gpu": {}
        })

    readonly property var emptyCurrent: ({
            "cpuUsage": NaN,
            "cpuFrequency": NaN,
            "cpuMaxFrequency": NaN,
            "cpuTemperature": NaN,
            "coreCount": NaN,
            "cores": [],
            "memTotal": 32e9,
            "memUsed": NaN,
            "memApplication": NaN,
            "memUsedPercent": NaN,
            "swapTotal": NaN,
            "swapUsed": NaN,
            "gpu": {}
        })

    readonly property var fullHistory: ({
            "times": [scene.now - 4000, scene.now - 2000, scene.now],
            "intervals": [2000, 2000, 2000],
            "cpu": [20, 30, 34],
            "ram": [50, 55, 58],
            "gpu": [null, null, null],
            "gpuId": null,
            "peakCpuTemp": 78,
            "peakGpuTemp": null
        })

    readonly property var gpuCurrent: ({
            "cpuUsage": 34,
            "memTotal": 32e9,
            "cores": [],
            "gpu": {
                "name": "Test GPU",
                "usage": 7,
                "temperature": 61,
                "hotspot": 71,
                "memTemperature": 66,
                "coreFrequency": 1800,
                "memoryFrequency": 1000,
                "usedVram": 6.2 * 1073741824,
                "totalVram": 16 * 1073741824,
                "power": 186,
                "fan": 1240
            }
        })

    readonly property var noGpuCurrent: ({
            "cpuUsage": 34,
            "memTotal": 32e9,
            "cores": [],
            "gpu": {
                "name": "Test GPU",
                "usage": NaN,
                "temperature": NaN,
                "hotspot": NaN,
                "memTemperature": NaN,
                "coreFrequency": NaN,
                "memoryFrequency": NaN,
                "usedVram": NaN,
                "totalVram": NaN,
                "power": NaN,
                "fan": NaN
            }
        })

    function gpuHistory(id: string): var {
        return {
            "times": [scene.now - 4000, scene.now - 2000, scene.now],
            "intervals": [2000, 2000, 2000],
            "cpu": [20, 30, 34],
            "ram": [50, 55, 58],
            "gpu": [5, 6, 7],
            "gpuId": id,
            "peakCpuTemp": 78,
            "peakGpuTemp": 74
        };
    }

    // The card the applet shows for the three states of the settings.
    readonly property string idOff: SensorCode.chosenGpu(false, ["gpu0"], "")
    readonly property string idOn: SensorCode.chosenGpu(true, ["gpu0"], "")
    readonly property string idNone: SensorCode.chosenGpu(true, [], "")

    readonly property var fullStats: ({
            "loadavg": [2.13, 1.8, 1.42],
            "ctxt": 1000,
            "psiCpu": 3,
            "psiMemory": 0.4,
            "memFree": 5e9,
            "shmem": 1e9,
            "zram": [
                {
                    "name": "zram0",
                    "orig": 2e9,
                    "compr": 6e8,
                    "used": 6.2e8
                }
            ],
            "governor": "schedutil",
            "epp": "balance_performance"
        })

    readonly property var fullRows: [
        {
            "name": "Firefox",
            "icon": "firefox",
            "kind": "app",
            "pids": [1, 2, 3],
            "cpu": 14.2,
            "memory": 4e9
        },
        {
            "name": "Background services",
            "icon": "",
            "kind": "service",
            "pids": [4, 5],
            "cpu": 2.8,
            "memory": 4e8
        },
        {
            "name": "Idle",
            "icon": "",
            "kind": "app",
            "pids": [6],
            "cpu": 0,
            "memory": 1e6
        }
    ]

    FullRepresentation {
        id: full

        width: implicitWidth
        current: scene.fullCurrent
        fresh: true
        history: scene.fullHistory
        graphMinutes: 5
        stats: scene.fullStats
        ctxtPerSecond: 41234
        hardwareInfo: ({
                "cpuModel": "AMD Ryzen 7 5800X3D",
                "physicalCores": 8,
                "memory": null
            })
        appRows: scene.fullRows
        onOpenSystemMonitor: scene.monitorOpened += 1
    }

    FullRepresentation {
        id: empty

        y: 700
        current: scene.emptyCurrent
        fresh: true
        stats: null
        ctxtPerSecond: NaN
        hardwareInfo: null
        appRows: []
    }

    FullRepresentation {
        id: gpuOff

        y: 1400
        current: scene.gpuCurrent
        fresh: true
        history: scene.gpuHistory("gpu0")
        gpuId: scene.idOff
    }

    FullRepresentation {
        id: gpuNone

        y: 1400
        current: scene.gpuCurrent
        fresh: true
        history: scene.gpuHistory("gpu0")
        gpuId: scene.idNone
    }

    FullRepresentation {
        id: gpuOn

        y: 2100
        current: scene.gpuCurrent
        fresh: true
        history: scene.gpuHistory("gpu0")
        gpuId: scene.idOn
    }

    FullRepresentation {
        id: gpuBlank

        y: 2800
        current: scene.noGpuCurrent
        fresh: true
        gpuId: scene.idOn
    }

    FullRepresentation {
        id: gpuOther

        y: 3500
        current: scene.gpuCurrent
        fresh: true
        history: scene.gpuHistory("gpu1")
        gpuId: scene.idOn
    }

    // The text with the decimal point of the locale the scene runs in.
    function local(text: string): string {
        return text.replace(/\./g, Qt.locale().decimalPoint);
    }

    function failedNames(checks): string {
        return Object.keys(checks).filter(name => !checks[name]).join(", ");
    }

    // Untyped on purpose: the repeaters hand out plain items.
    function itemOf(repeater: var, index: int): var {
        return repeater.itemAt(index);
    }

    // The widths of the segments of a memory bar added up.
    function segmentsWidth(bar: var): real {
        let sum = 0;
        for (let i = 0; i < bar.segmentRepeater.count; i++) {
            sum += scene.itemOf(bar.segmentRepeater, i).width;
        }
        return sum;
    }

    function fullRamProblem(): string {
        const ram = full.ramColumn;
        const bar = ram.stackedBar;
        return scene.failedNames({
            "head": ram.headLabel.text === scene.local("29.8 GiB"),
            "used": ram.usedLabel.visible && ram.usedLabel.text === scene.local("16.8 of 29.8 GiB used"),
            "percent": ram.percentLabel.text === "58 %",
            "segments": bar.visible && bar.segmentRepeater.count === 4 && bar.barWidth > 0,
            "segment widths": Math.abs(scene.segmentsWidth(bar) - bar.barWidth) <= 1,
            "swap": ram.swapRow.visible && ram.swapRow.text === scene.local("954 MiB of 7.5 GiB"),
            "zram": ram.zramRepeater.count === 1 && scene.itemOf(ram.zramRepeater, 0).text === scene.local("1.9 GiB → 572 MiB (3.3 : 1)"),
            "pressure": ram.pressureRow.visible && ram.pressureRow.text === scene.local("Waited 0.4 % of the time"),
            "consumers": ram.consumerList.visible && ram.consumerList.rowRepeater.count === 3
        });
    }

    function emptyRamProblem(): string {
        const ram = empty.ramColumn;
        return scene.failedNames({
            "head": ram.headLabel.text === scene.local("29.8 GiB"),
            "used": !ram.usedLabel.visible && !ram.stackedBar.visible,
            "segments": ram.stackedBar.segmentRepeater.count === 0,
            "swap": !ram.swapRow.visible,
            "zram": ram.zramRepeater.count === 0,
            "pressure": !ram.pressureRow.visible,
            "consumers": !ram.consumerList.visible
        });
    }

    // The columns of a popup that are shown.
    function columnCount(view: var): int {
        return view.cpuColumn.parent.visibleChildren.length;
    }

    function gpuProblem(): string {
        const gpu = gpuOn.gpuColumn;
        const thousands = Qt.locale().decimalPoint === "," ? "." : ",";
        return scene.failedNames({
            "off: two columns": scene.idOff === "" && !gpuOff.gpuColumn.visible && scene.columnCount(gpuOff) === 2,
            "no card: two columns": scene.idNone === "" && !gpuNone.gpuColumn.visible && scene.columnCount(gpuNone) === 2,
            "default: two columns": !full.gpuColumn.visible && scene.columnCount(full) === 2,
            "on: three columns": scene.idOn === "gpu0" && gpu.visible && scene.columnCount(gpuOn) === 3,
            "name": gpu.nameLabel.text === "Test GPU",
            "usage": gpu.usageTile.value === "7 %",
            "clock": gpu.clockTile.visible && gpu.clockTile.value === scene.local("1.80") && gpu.clockTile.detail === "GHz",
            "temperature": gpu.temperatureTile.visible && gpu.temperatureTile.value === "61 °C" && gpu.temperatureTile.detail === "Peak 74 °C",
            "power": gpu.powerTile.visible && gpu.powerTile.value === "186 W",
            "video memory": gpu.memoryRow.visible && gpu.memoryRow.text === scene.local("6.2 of 16.0 GiB") && Math.abs(gpu.memoryRow.fraction - 6.2 / 16) < 0.001,
            "details": gpu.detailsLabel.text === scene.local("Memory clock 1.00 GHz · Hotspot 71 °C · Memory 66 °C · Fan 1") + thousands + "240 RPM",
            "graph": gpu.graphWindow.times.length === 3 && gpu.graphWindow.gpu.join(",") === "5,6,7"
        });
    }

    function gpuBlankProblem(): string {
        const gpu = gpuBlank.gpuColumn;
        return scene.failedNames({
            "visible": gpu.visible && scene.columnCount(gpuBlank) === 3,
            "usage": gpu.usageTile.value === "–",
            "clock": !gpu.clockTile.visible,
            "temperature": !gpu.temperatureTile.visible,
            "power": !gpu.powerTile.visible,
            "video memory": !gpu.memoryRow.visible,
            "details": !gpu.detailsLabel.visible
        });
    }

    function gpuOtherProblem(): string {
        const gpu = gpuOther.gpuColumn;
        return scene.failedNames({
            "visible": gpu.visible,
            "empty graph": gpu.graphWindow.times.length === 0 && gpu.graphWindow.gpu.length === 0,
            "no peak": gpu.temperatureTile.detail === "" && gpu.temperatureTile.value === "61 °C"
        });
    }

    function fullProblem(): string {
        const cpu = full.cpuColumn;
        const rows = cpu.consumerList.rowRepeater;
        return scene.failedNames({
            "model": cpu.modelLabel.text === "AMD Ryzen 7 5800X3D",
            "topology": cpu.topologyLabel.text === "8 cores · 16 threads",
            "usage": cpu.usageTile.value === "34 %",
            "clock": cpu.clockTile.visible && cpu.clockTile.value === scene.local("4.12") && cpu.clockTile.detail === scene.local("GHz · max 4.55"),
            "temperature": cpu.temperatureTile.visible && cpu.temperatureTile.value === "63 °C" && cpu.temperatureTile.detail === "Peak 78 °C",
            "load": cpu.loadTile.visible && cpu.loadTile.value === scene.local("2.1 · 1.8 · 1.4"),
            "cores": cpu.coreGrid.visible && cpu.coreGrid.cellRepeater.count === 16 && scene.itemOf(cpu.coreGrid.cellRepeater, 15).valueText === "90",
            "details": cpu.detailsLabel.text === "Governor schedutil · EPP balance_performance · 41 k context switches/s · Waiting for CPU 3 %",
            "consumers": cpu.consumerList.visible && rows.count === 2,
            "graph": full.graphWindow.times.length === 3 && full.graphNow >= scene.now,
            "width": full.Layout.preferredWidth > 0 && full.Layout.preferredHeight > 0
        });
    }

    function emptyProblem(): string {
        const cpu = empty.cpuColumn;
        return scene.failedNames({
            "model": cpu.modelLabel.text === "",
            "topology": !cpu.topologyLabel.visible,
            "usage": cpu.usageTile.visible && cpu.usageTile.value === "–",
            "clock": !cpu.clockTile.visible,
            "temperature": !cpu.temperatureTile.visible,
            "load": !cpu.loadTile.visible,
            "cores": !cpu.coreGrid.visible,
            "details": !cpu.detailsLabel.visible,
            "consumers": !cpu.consumerList.visible,
            "graph": empty.graphWindow.times.length === 0
        });
    }

    Timer {
        interval: 500
        running: true
        onTriggered: {
            const fullWrong = scene.fullProblem();
            const emptyWrong = scene.emptyProblem();
            const ramWrong = scene.fullRamProblem();
            const emptyRamWrong = scene.emptyRamProblem();
            const gpuWrong = scene.gpuProblem();
            const gpuBlankWrong = scene.gpuBlankProblem();
            const gpuOtherWrong = scene.gpuOtherProblem();
            full.footer.children[0].clicked();
            const picked = scene.monitorOpened === 1;
            if (fullWrong === "" && emptyWrong === "" && ramWrong === "" && emptyRamWrong === "" && gpuWrong === "" && gpuBlankWrong === "" && gpuOtherWrong === "" && picked) {
                console.log("SMOKE OK popup");
                Qt.exit(0);
            } else {
                console.log("SMOKE FAIL popup: full wrong: " + fullWrong + "; empty wrong: " + emptyWrong + "; ram wrong: " + ramWrong + "; empty ram wrong: " + emptyRamWrong + "; gpu wrong: " + gpuWrong + "; gpu blank wrong: " + gpuBlankWrong + "; gpu other wrong: " + gpuOtherWrong + "; monitor " + scene.monitorOpened);
                Qt.exit(1);
            }
        }
    }
}
