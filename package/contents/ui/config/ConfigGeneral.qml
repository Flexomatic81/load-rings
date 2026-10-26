// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The general settings page. The fields follow with later releases; for now
// the page only holds the cfg_ properties of the configuration keys.

import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root

    property int cfg_configVersion
    property real cfg_updateInterval
    property int cfg_historyMinutes
    property bool cfg_showGpu
    property string cfg_gpuId
}
