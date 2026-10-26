// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for the general settings page, in plain qml6 (English fallback for the translation helpers). Checks
// that
//   - the page loads and starts with the saved values (interval in tenths of a second, time window, switch)
//   - the interval text "1,5" and "1.5" is read as 1.5 s, with the group separator and the unit ignored, and a
//     value the user enters is saved in seconds
//   - the time window follows the setting, also after a change from outside, and a choice is saved as a number
//   - the card list is off without the switch and with a single card, shows the name of each card, takes the first
//     card for an empty setting, and a choice is saved as the card ID
//   - without a card the hint is shown and the list is off

import QtQuick
import "../../package/contents/ui/config"

Item {
    id: scene

    width: 600
    height: 400

    property var failures: []
    property int step: 0
    property bool done: false

    function finish(ok, message) {
        if (scene.done) {
            return;
        }
        scene.done = true;
        console.log(message);
        Qt.exit(ok ? 0 : 1);
    }

    function expect(what, actual, expected) {
        if (actual !== expected) {
            const next = scene.failures.slice();
            next.push(what + ": got " + JSON.stringify(actual) + ", expected " + JSON.stringify(expected));
            scene.failures = next;
        }
    }

    // One check per timer tick, so that every change has been delivered through the event loop the way it is in
    // the settings dialog.
    function runStep() {
        switch (scene.step) {
        case 0:
            // Plasma fills the cfg_ properties; set the defaults of main.xml the way it does.
            page.cfg_updateInterval = 2;
            page.cfg_historyMinutes = 5;
            page.cfg_showGpu = false;
            page.cfg_gpuId = "";
            page.gpuOptions = [];
            break;
        case 1:
            scene.expect("interval shown in tenths", page.intervalBox.value, 20);
            scene.expect("interval range", page.intervalBox.from + "-" + page.intervalBox.to, "5-100");
            scene.expect("interval step", page.intervalBox.stepSize, 5);
            scene.expect("window at start", page.minutesBox.currentValue, 5);
            scene.expect("switch at start", page.showGpuBox.checked, false);
            scene.expect("no card: hint shown", page.noGpuLabel.visible, true);
            scene.expect("no card: list off", page.gpuBox.enabled, false);
            scene.expect("interval text", page.intervalBox.textFromValue(15, Qt.locale("en_US")), "1.5 s");
            scene.expect("interval text de", page.intervalBox.textFromValue(15, Qt.locale("de_DE")), "1,5 s");
            scene.expect("read 1,5 de", page.intervalBox.valueFromText("1,5 s", Qt.locale("de_DE")), 15);
            scene.expect("read 1.5 en", page.intervalBox.valueFromText("1.5", Qt.locale("en_US")), 15);
            scene.expect("read 10 de", page.intervalBox.valueFromText("10", Qt.locale("de_DE")), 100);
            scene.expect("read garbage keeps", page.intervalBox.valueFromText("abc", Qt.locale("en_US")), 20);
            // The user types 1,5 and confirms.
            page.intervalBox.contentItem.text = "1,5";
            page.intervalBox.value = page.intervalBox.valueFromText("1,5", Qt.locale("de_DE"));
            page.intervalBox.valueModified();
            page.minutesBox.currentIndex = 3;
            page.minutesBox.activated(3);
            break;
        case 2:
            scene.expect("interval saved as seconds", page.cfg_updateInterval, 1.5);
            scene.expect("interval type", typeof page.cfg_updateInterval, "number");
            scene.expect("window saved", page.cfg_historyMinutes, 60);
            scene.expect("window type", typeof page.cfg_historyMinutes, "number");
            page.cfg_historyMinutes = 15;
            page.gpuOptions = [{ text: "Radeon", value: "gpu0" }, { text: "GeForce", value: "gpu1" }];
            break;
        case 3:
            scene.expect("window after change", page.minutesBox.currentValue, 15);
            scene.expect("two cards: hint hidden", page.noGpuLabel.visible, false);
            scene.expect("switch off: list off", page.gpuBox.enabled, false);
            scene.expect("empty setting shows the first card", page.gpuBox.currentValue, "gpu0");
            scene.expect("card name shown", page.gpuBox.currentText, "Radeon");
            page.cfg_showGpu = true;
            break;
        case 4:
            scene.expect("switch follows", page.showGpuBox.checked, true);
            scene.expect("two cards and switch on: list on", page.gpuBox.enabled, true);
            page.gpuBox.currentIndex = 1;
            page.gpuBox.activated(1);
            break;
        case 5:
            scene.expect("card saved as ID", page.cfg_gpuId, "gpu1");
            scene.expect("card type", typeof page.cfg_gpuId, "string");
            page.showGpuBox.toggle();
            page.showGpuBox.toggled();
            page.gpuOptions = [{ text: "GeForce", value: "gpu1" }];
            break;
        case 6:
            scene.expect("switch saved", page.cfg_showGpu, false);
            scene.expect("switch type", typeof page.cfg_showGpu, "boolean");
            page.cfg_showGpu = true;
            break;
        case 7:
            scene.expect("one card: list off", page.gpuBox.enabled, false);
            scene.expect("one card: hint hidden", page.noGpuLabel.visible, false);
            if (scene.failures.length === 0) {
                scene.finish(true, "SMOKE OK config general");
            } else {
                scene.finish(false, "SMOKE FAIL config general: " + scene.failures.join("; "));
            }
            return;
        }
        scene.step++;
        stepTimer.restart();
    }

    ConfigGeneral {
        id: page

        anchors.fill: parent
    }

    Timer {
        id: stepTimer

        interval: 100
        running: true
        onTriggered: scene.runStep()
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: scene.finish(false, "SMOKE FAIL config general: timeout at step " + scene.step)
    }
}
