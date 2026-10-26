// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// Reads the programs of the session with their CPU and memory use from the
// application model of libksysguard, only while active is true (the popup is
// open). The processes of the session's background cgroups are collected into
// one row of kind "service".
//
// Measured with libksysguard 6.8.1: the model's usage counts per core, and a
// second model with its root set to /system.slice stays empty, so system
// services are not listed (see apps.mjs).

import QtQuick
import org.kde.ksysguard.process as Process
import "../../code/apps.mjs" as AppsCode

Item {
    id: root

    // True while the values are wanted (the popup is open). The model is off otherwise.
    property bool active: false
    // Logical CPUs, NaN while unknown; without it there is no CPU share.
    property real coreCount: NaN
    // The (translated) name of the row that collects the background services.
    property string servicesName

    // The rows of the model as { name, icon, kind, pids, cpu, memory }: cpu as a
    // percentage of the whole CPU (null while unknown), memory in bytes. Empty
    // while not active.
    property var rows: []
    // False when the system has no session cgroups to read.
    readonly property bool available: model.available

    // True while the model reads the processes; follows active. A function, not a property: the model does not
    // signal changes of enabled (measured with libksysguard 6.8.1), so a binding would not follow it.
    function isReading(): bool {
        return model.enabled;
    }

    onActiveChanged: internals.refresh()
    onCoreCountChanged: internals.schedule()

    QtObject {
        id: internals

        property bool pending: false

        function schedule() {
            if (!internals.pending) {
                internals.pending = true;
                Qt.callLater(internals.refresh);
            }
        }

        function cell(row: int, attribute: string): var {
            const column = model.enabledAttributes.indexOf(attribute);
            return column < 0 ? undefined : model.data(model.index(row, column), Process.ProcessDataModel.Value);
        }

        function refresh() {
            internals.pending = false;
            if (!root.active) {
                root.rows = [];
                return;
            }
            const result = [];
            for (let row = 0; row < model.rowCount(); row++) {
                result.push(AppsCode.readRow({
                    "name": internals.cell(row, "appName"),
                    "icon": internals.cell(row, "iconName"),
                    "menuId": internals.cell(row, "menuId"),
                    "usage": internals.cell(row, "usage"),
                    // The model reports memory in KiB.
                    "memoryKiB": internals.cell(row, "memory"),
                    "pids": model.data(model.index(row, 0), Process.ProcessDataModel.PIDs)
                }, root.coreCount));
            }
            root.rows = result;
        }
    }

    Process.ApplicationDataModel {
        id: model

        enabled: root.active
        enabledAttributes: ["appName", "iconName", "usage", "memory", "menuId"]

        // As in the Applications page of the KDE System Monitor: the session's
        // background cgroups and a few background programs form one row.
        cgroupMapping: ({
            "session.slice": AppsCode.SERVICES_ID,
            "background.slice": AppsCode.SERVICES_ID,
            "org.a11y.atspi.Registry": AppsCode.SERVICES_ID,
            "org.kde.discover.notifier": AppsCode.SERVICES_ID,
            "geoclue": AppsCode.SERVICES_ID,
            "org.kde.kunifiedpush": AppsCode.SERVICES_ID,
            "dconf.service": AppsCode.SERVICES_ID,
            "flatpak-session-helper.service": AppsCode.SERVICES_ID,
            "gpg-agent.service": AppsCode.SERVICES_ID,
            "org.kde.xwaylandvideobridge": AppsCode.SERVICES_ID,
            "org.kde.kalendarac": AppsCode.SERVICES_ID,
            "xdg-desktop-portal-gtk.service": AppsCode.SERVICES_ID,
            "org.kde.kdeconnect": AppsCode.SERVICES_ID,
            "org.kde.kwalletd6": AppsCode.SERVICES_ID,
            "org.kde.kclockd": AppsCode.SERVICES_ID
        })
        // The key and menuId must equal AppsCode.SERVICES_ID; readRow() tells the row apart by its menuId.
        applicationOverrides: ({
                "services": {
                    "menuId": AppsCode.SERVICES_ID,
                    "appName": root.servicesName,
                    "iconName": "preferences-system-services"
                }
            })

        onDataChanged: internals.schedule()
        onRowsInserted: internals.schedule()
        onRowsRemoved: internals.schedule()
        onModelReset: internals.schedule()
    }
}
