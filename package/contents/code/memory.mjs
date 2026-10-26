// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 Flexomatic81

// The memory bar of the popup: how the physical memory divides into
// programs, system, cache and free memory, and the ZRAM compression ratio.

function finite(value) {
  return typeof value === "number" && Number.isFinite(value);
}

// The raw parts in bar order, each as { key, bytes } and possibly negative.
function rawParts(total, used, application, memFree) {
  const apps = finite(application) ? application : 0;
  const parts = [
    { key: "apps", bytes: apps },
    { key: "other", bytes: used - apps },
  ];
  if (finite(memFree)) {
    parts.push({ key: "cache", bytes: total - used - memFree });
    parts.push({ key: "free", bytes: memFree });
  } else {
    parts.push({ key: "available", bytes: total - used });
  }
  return parts;
}

// The segments of the memory bar, left to right, in bytes. Negative parts
// become 0, no part reaches beyond what is left of the total, and the last
// segment takes the remainder, so the sum is always the total. Without the
// total or the used memory there is no bar.
export function memoryBreakdown({ total, used, application, memFree }) {
  if (!finite(total) || !finite(used) || total <= 0) return [];
  const parts = rawParts(total, used, application, memFree);
  const result = [];
  let left = total;
  for (let i = 0; i < parts.length; i++) {
    const last = i === parts.length - 1;
    const bytes = last ? left : Math.min(Math.max(parts[i].bytes, 0), left);
    result.push({ key: parts[i].key, bytes: bytes });
    left -= bytes;
  }
  return result;
}

// Uncompressed over compressed size, to one decimal, or null when there is
// nothing compressed.
export function zramRatio({ orig, compr }) {
  if (!finite(orig) || !finite(compr) || compr <= 0) return null;
  return Math.round((orig / compr) * 10) / 10;
}
