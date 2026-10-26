// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Smoke scene for the core grid with 128 logical CPUs: 32 columns, no wider than a popup column, every cell
// created and at least a few pixels wide.

import QtQuick
import org.kde.kirigami as Kirigami
import "../../package/contents/ui/full"
import "../../package/contents/code/layout.mjs" as LayoutLogic

Item {
    id: scene

    width: 1000
    height: 600

    readonly property real columnWidth: LayoutLogic.popupColumnWidth(Kirigami.Units.gridUnit)

    CoreGrid {
        id: grid

        cores: Array.from({
            length: 128
        }, (_, i) => ({
                    "usage": i % 101,
                    "frequency": 3000,
                    "temperature": 50
                }))
    }

    Timer {
        interval: 300
        running: true
        onTriggered: {
            const checks = {
                "implicitWidth": grid.implicitWidth <= scene.columnWidth,
                "contentWidth": grid.contentWidth <= scene.columnWidth,
                "columns": grid.columns === 32,
                "cells": grid.cellRepeater.count === 128,
                "cellWidth": grid.cellWidth >= 4,
                "height": grid.implicitHeight > 0
            };
            const wrong = Object.keys(checks).filter(name => !checks[name]).join(", ");
            if (wrong === "") {
                console.log("SMOKE OK core grid");
                Qt.exit(0);
            } else {
                console.log("SMOKE FAIL core grid: " + wrong + " (implicit " + grid.implicitWidth + ", content " + grid.contentWidth + ", column " + scene.columnWidth + ")");
                Qt.exit(1);
            }
        }
    }
}
