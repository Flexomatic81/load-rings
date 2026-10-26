// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Stands in for CommandRunner.qml when plasma5support is missing: it imports
// a module that does not exist, so loading it fails. Used by
// NoRunnerSmoke.qml.

import QtQuick
import org.kde.loadrings.missingrunner // qmllint disable import

Item {
}
