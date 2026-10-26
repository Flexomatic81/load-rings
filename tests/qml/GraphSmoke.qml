// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for the usage graph and the range tabs: a graph with a gap renders without a warning, its paths
// have two sections, and a click on a tab reports its window.

import QtQuick
import "../../package/contents/ui/full"

Item {
    id: scene

    width: 400
    height: 200

    property var picks: []

    UsageGraph {
        id: graph

        width: 300
        height: 80
        times: [0, 10000, 20000, 30000, 40000, 50000, 60000]
        values: [10, 40, 80, null, 20, 60, 100]
        minutes: 1
        now: 60000
    }

    RangeTabs {
        id: tabs

        y: 100
        minutes: 5
        onPicked: m => scene.picks = scene.picks.concat([m])
    }

    function sections(path: string): int {
        return path.split("M").length - 1;
    }

    Timer {
        interval: 300
        running: true
        onTriggered: {
            const good = scene.sections(graph.paths.line) === 2 && scene.sections(graph.paths.fill) === 2 && graph.paths.line.length > 0;
            const first = tabs.children[0];
            const last = tabs.children[3];
            first.clicked();
            last.clicked();
            const picked = JSON.stringify(scene.picks) === "[1,60]";
            if (good && picked && tabs.minutes === 5) {
                console.log("SMOKE OK graph");
                Qt.exit(0);
            } else {
                console.log("SMOKE FAIL graph " + good + " " + JSON.stringify(scene.picks));
                Qt.exit(1);
            }
        }
    }
}
