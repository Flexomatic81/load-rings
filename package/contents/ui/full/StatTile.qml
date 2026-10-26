// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// One figure of a popup column: a small label, the value in large tabular digits and a note below it.

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property string label
    property string value
    // The line below the value; hidden when empty.
    property string detail
    property color valueColor: Kirigami.Theme.textColor

    implicitWidth: Math.max(labelText.implicitWidth, valueText.implicitWidth) + 2 * Kirigami.Units.smallSpacing
    implicitHeight: content.implicitHeight + 2 * Kirigami.Units.smallSpacing
    radius: Kirigami.Units.cornerRadius
    color: Qt.alpha(Kirigami.Theme.textColor, 0.05)

    ColumnLayout {
        id: content

        // Top-aligned: a tile stretched to the height of its neighbours keeps its value in line with theirs.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: 0

        QQC2.Label {
            id: labelText

            Layout.fillWidth: true
            text: root.label
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.disabledTextColor
            elide: Text.ElideRight
        }

        QQC2.Label {
            id: valueText

            Layout.fillWidth: true
            text: root.value
            color: root.valueColor
            font.pixelSize: Math.round(Kirigami.Units.gridUnit * 1.1)
            font.weight: Font.Light
            font.features: { "tnum": 1 }
            // Long values (the load averages) shrink to the tile instead of being cut.
            fontSizeMode: Text.HorizontalFit
            verticalAlignment: Text.AlignVCenter
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit * 0.6)
        }

        QQC2.Label {
            id: detailText

            Layout.fillWidth: true
            visible: root.detail !== ""
            text: root.detail
            font: Kirigami.Theme.smallFont
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
        }
    }
}
