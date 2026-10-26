// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// A stand-in for the data parts of the applet (SystemSensors, ProcStats, HardwareInfo, AppsSource, GpuChoices)
// with the fixed demo data of demo.mjs: everything the panel view, the popup and the settings page read.

import QtQml
import "demo.mjs" as Demo

QtObject {
    id: root

    // The history ends now, so that the popup graphs show it.
    readonly property double now: Date.now()

    readonly property var current: Demo.demoCurrent()
    readonly property var history: Demo.demoHistory(root.now)
    readonly property var stats: Demo.demoStats()
    readonly property real ctxtPerSecond: Demo.DEMO_CONTEXT_SWITCHES
    readonly property var hardwareInfo: Demo.demoHardware()
    readonly property var appRows: Demo.demoApps()
    readonly property string gpuId: Demo.DEMO_GPU_ID
    readonly property var gpuOptions: Demo.demoGpuOptions()

    readonly property var rings: Demo.demoRings(false)
    readonly property var ringsWithGpu: Demo.demoRings(true)
    readonly property var colorRings: Demo.colorRings()
}
