// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Renders the panel view, the popup and the settings page with the demo data of DemoProvider and saves them as PNG
// files, then quits. Run it through scripts/screenshots.sh:
//
//   qml6 tools/screenshots/Screenshots.qml -- <output directory>
//
// The panel views: the processor and memory rings in a horizontal panel 44 px high, the same with the graphics
// card, a vertical panel 48 px wide with all three, and five rings from low to high load for the colors, each on
// the background color of the theme. The popup has its preferred size, once with two columns (the default) and once
// with the graphics card; the settings page has a fixed width and the graphics card switched on. The text uses the
// first available of the fonts in demo.mjs; the colors come from the color scheme the calling script sets up (a
// stock Breeze scheme).
//
// Output: "SCREENSHOT theme <#rrggbb>" with the background color of the theme, "SCREENSHOT saved <file>
// <width>x<height>" per image, the processor graph of the popup as "SCREENSHOT chart popup.png <x> <y> <width>
// <height> of <width> <height>" and the memory bar the same way as "SCREENSHOT bar …" (both for check-images.mjs),
// and "SCREENSHOTS OK" or "SCREENSHOTS FAIL <reason>" at the end.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../../package/contents/ui/compact"
import "../../package/contents/ui/full"
import "../../package/contents/ui/config"
import "demo.mjs" as Demo

QQC2.ApplicationWindow {
    id: scene

    // The panel thickness and the width of the vertical panel.
    readonly property int panelHeight: 44
    readonly property int verticalWidth: 48
    // Room around the views on their panel background.
    readonly property int padding: 6
    readonly property string family: Demo.pickFont(Qt.fontFamilies())
    // The output directory: the argument after "--".
    readonly property string outDir: {
        const args = Qt.application.arguments;
        const at = args.indexOf("--");
        return at >= 0 && at + 1 < args.length ? args[at + 1] : "";
    }
    property int next: 0
    property bool done: false
    readonly property var shots: [panelShot, gpuPanelShot, verticalShot, colorsShot, popupShot, gpuPopupShot, settingsShot]

    width: 2200
    height: 1300
    visible: true
    title: "Load Rings screenshots"
    color: Kirigami.Theme.backgroundColor
    font.family: scene.family

    function finish(ok: bool, message: string) {
        if (scene.done) {
            return;
        }
        scene.done = true;
        console.log(ok ? "SCREENSHOTS OK" : "SCREENSHOTS FAIL " + message);
        Qt.exit(ok ? 0 : 1);
    }

    // Logs the area of `item` in popup.png as "SCREENSHOT <kind> popup.png …"; false when it has no size.
    function reportArea(kind: string, item: Item): bool {
        if (item === null || !item.visible || item.width <= 0 || item.height <= 0) {
            return false;
        }
        const pos = item.mapToItem(popupShot, 0, 0);
        console.log("SCREENSHOT " + kind + " popup.png " + pos.x.toFixed(1) + " " + pos.y.toFixed(1) + " " + item.width.toFixed(1) + " " + item.height.toFixed(1) + " of " + popupShot.width + " " + popupShot.height);
        return true;
    }

    // The first item below `item` for which `match` is true; null if none.
    function findItem(item: Item, match: var): Item {
        for (let i = 0; i < item.children.length; i++) {
            const child = item.children[i];
            if (match(child)) {
                return child;
            }
            const inner = scene.findItem(child, match);
            if (inner !== null) {
                return inner;
            }
        }
        return null;
    }

    // The background color of the theme, so the scripts can check that the stock color scheme they set up is the
    // one in use.
    function reportTheme(): bool {
        console.log("SCREENSHOT theme " + Kirigami.Theme.backgroundColor);
        return true;
    }

    // The processor graph of the popup.
    function reportChart(): bool {
        return scene.reportArea("chart", scene.findItem(popup.cpuColumn, child => child instanceof UsageGraph));
    }

    // The memory bar of the popup.
    function reportBar(): bool {
        return scene.reportArea("bar", popup.ramColumn.stackedBar);
    }

    // Saves the shot `scene.next` and goes on with the following one.
    function grabNext() {
        if (scene.next >= scene.shots.length) {
            scene.finish(true, "");
            return;
        }
        const item = scene.shots[scene.next];
        const name = Demo.SHOTS[scene.next];
        const started = item.grabToImage(result => {
            const file = scene.outDir + "/" + name;
            if (!result.saveToFile(file)) {
                scene.finish(false, "could not write " + name);
                return;
            }
            console.log("SCREENSHOT saved " + name + " " + item.width + "x" + item.height);
            scene.next++;
            scene.grabNext();
        });
        if (!started) {
            scene.finish(false, "could not grab " + name);
        }
    }

    function start() {
        if (scene.outDir === "") {
            scene.finish(false, "no output directory: pass it after --");
        } else if (scene.family === "") {
            scene.finish(false, "none of the fonts " + Demo.DEMO_FONTS.join(", ") + " is installed");
        } else if (!scene.reportTheme() || !scene.reportChart()) {
            scene.finish(false, "the popup has no processor graph");
        } else if (!scene.reportBar()) {
            scene.finish(false, "the popup has no memory bar");
        } else {
            scene.grabNext();
        }
    }

    // A horizontal panel of panelHeight with one panel view.
    component PanelShot: Rectangle {
        id: shot

        property alias rings: panelView.rings

        width: host.width + scene.padding * 2
        height: scene.panelHeight
        color: Kirigami.Theme.backgroundColor

        RowLayout {
            id: host

            x: scene.padding
            height: shot.height
            spacing: 0

            CompactRepresentation {
                id: panelView

                Layout.fillHeight: true
            }
        }
    }

    // A popup on the background of the theme, at its preferred size.
    component PopupShot: Rectangle {
        id: popupFrame

        property alias view: popupView

        width: popupView.width
        height: popupView.height
        color: Kirigami.Theme.backgroundColor

        FullRepresentation {
            id: popupView

            current: demo.current
            fresh: true
            history: demo.history
            graphMinutes: 5
            stats: demo.stats
            ctxtPerSecond: demo.ctxtPerSecond
            hardwareInfo: demo.hardwareInfo
            appRows: demo.appRows
            width: popupView.Layout.preferredWidth
            height: popupView.Layout.preferredHeight
        }
    }

    DemoProvider {
        id: demo
    }

    Column {
        x: 20
        y: 20
        spacing: 20

        PanelShot {
            id: panelShot

            rings: demo.rings
        }

        PanelShot {
            id: gpuPanelShot

            rings: demo.ringsWithGpu
        }

        PanelShot {
            id: colorsShot

            rings: demo.colorRings
        }

        Rectangle {
            id: verticalShot

            width: scene.verticalWidth
            height: verticalHost.height + scene.padding * 2
            color: Kirigami.Theme.backgroundColor

            ColumnLayout {
                id: verticalHost

                y: scene.padding
                width: verticalShot.width
                spacing: 0

                CompactRepresentation {
                    rings: demo.ringsWithGpu
                    vertical: true
                    Layout.fillWidth: true
                }
            }
        }
    }

    PopupShot {
        id: popupShot

        x: 320
        y: 20
    }

    PopupShot {
        id: gpuPopupShot

        x: 320
        y: popupShot.y + popupShot.height + 20
        view.gpuId: demo.gpuId
    }

    readonly property FullRepresentation popup: popupShot.view

    // The settings page with the graphics card switched on; Plasma fills the cfg_ properties the same way.
    Rectangle {
        id: settingsShot

        x: 20
        y: 400
        width: 560
        height: settingsPage.implicitHeight
        color: Kirigami.Theme.backgroundColor

        ConfigGeneral {
            id: settingsPage

            anchors.fill: parent
            cfg_configVersion: 1
            cfg_updateInterval: 2
            cfg_historyMinutes: 5
            cfg_showGpu: true
            cfg_gpuId: demo.gpuId
            gpuOptions: demo.gpuOptions
        }
    }

    // The views need a moment to lay out and the icons to load.
    Timer {
        interval: 1500
        running: true
        onTriggered: scene.start()
    }

    Timer {
        interval: 30000
        running: true
        onTriggered: scene.finish(false, "timed out")
    }
}
