// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Reads the processor model, the physical core count and the memory modules
// once. Without plasma5support there is nobody to ask: info stays null.

import QtQuick
import "../../code/hardware.mjs" as Hardware

Item {
    id: root

    // Result of parseHardware(), or null while unknown or unavailable.
    property var info: null
    // True once load() has started the query; it never runs a second time.
    readonly property bool started: internals.started

    // Starts the query. Only the first call has an effect.
    function load() {
        if (internals.started) {
            return;
        }
        internals.started = true;
        const runner = internals.runner();
        if (runner !== null) {
            runner.run();
        }
    }

    QtObject {
        id: internals

        property bool started: false

        // The CommandRunner behind the query, null while it is not loaded.
        // Its properties are only known at runtime, hence the untyped result.
        function runner(): var {
            return runnerLoader.item;
        }

        function apply(exitCode, stdout, stderr) {
            if (exitCode !== 0) {
                console.warn("loadrings: hardware query failed (exit " + exitCode + "): " + stderr);
                return;
            }
            root.info = Hardware.parseHardware(stdout);
        }
    }

    Loader {
        id: runnerLoader

        source: "CommandRunner.qml"

        onLoaded: {
            const runner = internals.runner();
            runner.command = Hardware.HARDWARE_COMMAND;
            runner.timeoutMs = 10000;
            runner.finished.connect(internals.apply);
        }
    }
}
