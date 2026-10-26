// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The programs that use the most CPU and memory, from the rows of the
// application model of libksysguard (org.kde.ksysguard.process).
//
// Measured with libksysguard 6.8.1 on 16 logical CPUs, one `yes > /dev/null`
// running: its application row read usage 105 while cpu/all/usage read about
// 8-13 %, so the model's usage counts per core (100 = one core busy) and is not
// normalized to the whole CPU.
//
// The model lists the application cgroups below the user's systemd instance
// (user@UID.service). With its root set to /system.slice it stayed empty for
// 12 s while system services were running, so system services cannot be
// listed; the only "service" row is the one that collects the session's
// background services (session.slice and background.slice, see AppsSource.qml).

// Whether the model's usage is already a share of the whole CPU.
export const USAGE_NORMALIZED = false;

// The menu id the background services row gets (see AppsSource.qml).
export const SERVICES_ID = "services";

function finite(value) {
  return typeof value === "number" && Number.isFinite(value);
}

// The usage of a program as a percentage of the whole CPU, or null without the
// numbers needed.
export function cpuShare(usage, coreCount, normalized) {
  if (!finite(usage)) return null;
  if (normalized) return usage;
  return finite(coreCount) && coreCount > 0 ? usage / coreCount : null;
}

// A copy of the process ids as a plain array (QML hands over a list-like object).
function pidList(pids) {
  const result = [];
  if (pids === null || typeof pids !== "object" || !finite(pids.length)) return result;
  for (let i = 0; i < pids.length; i++) result.push(pids[i]);
  return result;
}

// A row of the model, read as { name, icon, menuId, usage, memoryKiB, pids },
// as a row for topConsumers: memory in bytes, cpu as a share of the whole CPU.
export function readRow(raw, coreCount) {
  const memoryKiB = raw.memoryKiB;
  return {
    name: raw.name === undefined || raw.name === null ? "" : String(raw.name),
    icon: typeof raw.icon === "string" ? raw.icon : "",
    kind: raw.menuId === SERVICES_ID ? "service" : "app",
    pids: pidList(raw.pids),
    cpu: cpuShare(raw.usage, coreCount, USAGE_NORMALIZED),
    memory: finite(memoryKiB) ? memoryKiB * 1024 : null,
  };
}

function compareNames(a, b) {
  if (a < b) return -1;
  return a > b ? 1 : 0;
}

function shareOf(value, total) {
  if (!finite(total) || total <= 0) return null;
  return Math.min(Math.max(value / total, 0), 1);
}

// The `limit` rows with the highest `key` ("cpu" or "memory"), highest first,
// ties by name. Rows without processes or without a positive value are left
// out. share is the value as a part of `total` (0..1), null without a total.
export function topConsumers(rows, key, total, limit = 5) {
  const list = [];
  for (const row of rows || []) {
    const value = row[key];
    if (!finite(value) || value <= 0 || !row.pids || row.pids.length === 0) continue;
    list.push({
      name: row.name,
      icon: row.icon,
      kind: row.kind,
      processCount: row.pids.length,
      value: value,
      share: shareOf(value, total),
    });
  }
  list.sort((a, b) => b.value - a.value || compareNames(a.name, b.name));
  return list.slice(0, limit);
}
