// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for CompactRepresentation: two and three rings in a horizontal (44 px high) and a vertical (30 px
// wide) panel, the sizes against ringLayout, the dash of a ring without a value, and the click signal.
// plasmawindowed does not instantiate the compact view, so this scene is the only runtime check of its bindings.

import QtQuick
import "../../package/contents/ui/compact"
import "../../package/contents/code/layout.mjs" as Layout

Item {
    id: scene

    width: 400
    height: 400

    property bool done: false
    property int clicks: 0
    property var order: []
    property var failures: []

    readonly property var three: [
        {
            key: "cpu",
            percent: 34
        },
        {
            key: "ram",
            percent: NaN
        },
        {
            key: "gpu",
            percent: 99.6
        }
    ]

    function finish(ok, message) {
        if (scene.done) {
            return;
        }
        scene.done = true;
        console.log(message);
        Qt.exit(ok ? 0 : 1);
    }

    // Untyped on purpose: the repeater hands out plain items.
    function ringAt(view, index): var {
        return view.ringRepeater.itemAt(index);
    }

    function expect(name, actual, wanted) {
        if (actual !== wanted) {
            scene.failures = scene.failures.concat([name + ": " + actual + " != " + wanted]);
        }
    }

    function checkSize(name, view, vertical, thickness, count) {
        const wanted = Layout.ringLayout({
            vertical: vertical,
            thickness: thickness,
            count: count
        });
        scene.expect(name + " width", view.implicitWidth, wanted.width);
        scene.expect(name + " height", view.implicitHeight, wanted.height);
        scene.expect(name + " rings", view.ringRepeater.count, count);
        scene.expect(name + " diameter", view.ringRepeater.itemAt(0)?.diameter, wanted.diameter);
        scene.expect(name + " stroke", view.ringRepeater.itemAt(0)?.stroke, wanted.stroke);
    }

    Column {
        CompactRepresentation {
            id: horizontal2


            width: 200
            height: 44
            rings: [
                {
                    key: "cpu",
                    percent: 34
                },
                {
                    key: "ram",
                    percent: 58
                }
            ]
            onPressed: scene.order = scene.order.concat(["pressed"])
            onClicked: {
                scene.clicks += 1;
                scene.order = scene.order.concat(["clicked"]);
            }
        }
        CompactRepresentation {
            id: horizontal3


            width: 200
            height: 44
            rings: scene.three
        }
        CompactRepresentation {
            id: vertical2


            vertical: true
            width: 30
            height: 100
            rings: [
                {
                    key: "cpu",
                    percent: 34
                },
                {
                    key: "ram",
                    percent: 58
                }
            ]
        }
        CompactRepresentation {
            id: vertical3


            vertical: true
            width: 30
            height: 100
            rings: scene.three
        }
    }

    Timer {
        interval: 200
        running: true
        onTriggered: {
            scene.checkSize("horizontal 2", horizontal2, false, 44, 2);
            scene.checkSize("horizontal 3", horizontal3, false, 44, 3);
            scene.checkSize("vertical 2", vertical2, true, 30, 2);
            scene.checkSize("vertical 3", vertical3, true, 30, 3);
            scene.expect("dash", scene.ringAt(horizontal3, 1).text, "–");
            scene.expect("number", scene.ringAt(horizontal3, 0).text, "34");
            scene.expect("rounded", scene.ringAt(vertical3, 2).text, "100");
            scene.expect("no arc without a value", scene.ringAt(vertical3, 1).hasArc, false);
            scene.expect("arc with a value", scene.ringAt(vertical3, 0).hasArc, true);
            // A changed percent updates the ring in place; the ring items are not rebuilt.
            const before = scene.ringAt(horizontal2, 0);
            horizontal2.rings = [
                {
                    key: "cpu",
                    percent: 80
                },
                {
                    key: "ram",
                    percent: NaN
                }
            ];
            scene.expect("same ring item after a percent change", scene.ringAt(horizontal2, 0) === before, true);
            scene.expect("percent changed in place", before.text, "80");
            scene.expect("percent lost in place", scene.ringAt(horizontal2, 1).text, "–");
            horizontal2.pressed();
            horizontal2.clicked();
            scene.expect("press before click", scene.order.join(","), "pressed,clicked");
            scene.expect("click", scene.clicks, 1);
            if (scene.failures.length > 0) {
                scene.finish(false, "SMOKE FAIL compact: " + scene.failures.join("; "));
            } else {
                scene.finish(true, "SMOKE OK compact");
            }
        }
    }
}
