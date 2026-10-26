// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// A labelled bar with a text after it, e.g. "Swap ▬▬▭▭ 0.3 of 8 GiB".

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../code/popup.mjs" as Popup

RowLayout {
    id: root

    property string label
    // The filled part of the bar, 0..1.
    property real fraction: 0
    property string text
    property color barColor: Kirigami.Theme.highlightColor

    spacing: Kirigami.Units.largeSpacing

    QQC2.Label {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
        text: root.label
        font: Kirigami.Theme.smallFont
        elide: Text.ElideRight
    }

    Rectangle {
        id: track

        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(Kirigami.Units.smallSpacing * 1.5)
        radius: track.height / 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

        Rectangle {
            width: track.width * Popup.barFraction(root.fraction)
            height: track.height
            radius: track.radius
            color: root.barColor
        }
    }

    QQC2.Label {
        text: root.text
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.features: { "tnum": 1 }
    }
}
