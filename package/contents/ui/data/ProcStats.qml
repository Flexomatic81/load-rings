// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Reads the running kernel statistics (load average, context switches,
// pressure, memory, ZRAM, governor) while active is true. Without
// plasma5support there is nobody to ask: stats stays null.

import QtQuick
import "../../code/procstats.mjs" as ProcStatsCode

Item {
    id: root

    // True while the values are wanted (the popup is open). Nothing runs otherwise.
    property bool active: false
    // Time between two readings in milliseconds.
    property int interval: 2000
    // File of the command runner. Only a test replaces it.
    property url runnerSource: "CommandRunner.qml"

    // Result of the latest parseStats(), or null while unknown or unavailable.
    property var stats: null
    // Context switches per second, NaN until two readings exist.
    property real ctxtPerSecond: NaN

    onActiveChanged: {
        if (!root.active) {
            // The next reading after a pause must not be compared with an old one.
            internals.previous = null;
            root.ctxtPerSecond = NaN;
        }
    }

    QtObject {
        id: internals

        // The latest { timestamp, ctxt }, or null.
        property var previous: null

        // The CommandRunner behind the query, null while it is not loaded.
        // Its properties are only known at runtime, hence the untyped result.
        function runner(): var {
            return runnerLoader.item;
        }

        function read() {
            const runner = internals.runner();
            if (runner !== null) {
                runner.run();
            }
        }

        function apply(exitCode, stdout, stderr) {
            if (exitCode !== 0) {
                console.warn("loadrings: statistics query failed (exit " + exitCode + "): " + stderr);
                return;
            }
            // A reading that finishes after the popup closed is dropped.
            if (!root.active) {
                return;
            }
            const parsed = ProcStatsCode.parseStats(stdout);
            root.stats = parsed;
            if (parsed.ctxt === null) {
                internals.previous = null;
                root.ctxtPerSecond = NaN;
                return;
            }
            const reading = {
                "timestamp": Date.now(),
                "ctxt": parsed.ctxt
            };
            const rate = ProcStatsCode.ctxtRate(internals.previous, reading);
            internals.previous = reading;
            root.ctxtPerSecond = rate === null ? NaN : rate;
        }
    }

    Timer {
        id: timer

        interval: Math.max(1, root.interval)
        repeat: true
        triggeredOnStart: true
        running: root.active
        onTriggered: internals.read()
    }

    Loader {
        id: runnerLoader

        source: root.runnerSource

        onLoaded: {
            const runner = internals.runner();
            runner.command = ProcStatsCode.STATS_COMMAND;
            runner.timeoutMs = 10000;
            runner.finished.connect(internals.apply);
            // The timer may have fired before the runner existed.
            if (root.active) {
                internals.read();
            }
        }
    }
}
