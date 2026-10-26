// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene that loads every code module in the QML engine and calls one
// cheap function of each. Node accepts syntax that the QML JavaScript engine
// rejects, so the Node tests alone cannot prove a module is usable in QML.
// Every file in package/contents/code must be imported here (a Node test
// checks that).

import QtQuick
import "../../package/contents/code/color.mjs" as Color
import "../../package/contents/code/command.mjs" as Command
import "../../package/contents/code/format.mjs" as Format
import "../../package/contents/code/hardware.mjs" as Hardware
import "../../package/contents/code/history.mjs" as History
import "../../package/contents/code/layout.mjs" as Layout
import "../../package/contents/code/procstats.mjs" as ProcStats
import "../../package/contents/code/sensors.mjs" as Sensors
import "../../package/contents/code/text.mjs" as Text

Item {
    id: scene

    function check() {
        const results = [
            Color.ringColor(50) === "#fdbc4b",
            Command.shellQuote("a") === "'a'",
            Format.formatCount(41234, ",") === "41 k",
            Hardware.parseHardware("@@cpuinfo\nmodel name\t: X 8-Core Processor\n").cpuModel === "X",
            History.validMinutes(7) === 5,
            Layout.ringLayout({ vertical: false, thickness: 44, count: 2 }).width === 92,
            ProcStats.parseStats("@@stat\nctxt 7\n").ctxt === 7,
            Sensors.pickGpu(["gpu0"], "") === "gpu0",
            Text.substitute("%1", ["x"]) === "x"
        ];
        const bad = results.indexOf(false);
        if (bad >= 0) {
            console.log("failed check " + bad);
        }
        return bad < 0;
    }

    Component.onCompleted: {
        if (scene.check()) {
            console.log("SMOKE OK modules");
            Qt.exit(0);
        } else {
            console.log("SMOKE FAIL modules");
            Qt.exit(1);
        }
    }
}
