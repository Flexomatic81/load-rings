#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# SPDX-FileCopyrightText: 2026 Flexomatic81

# Checks that the screenshot scene runs, without writing into docs/: renders
# it on the offscreen platform into the directory in LOADRINGS_SCREENSHOT_DIR
# (created if missing), with the stock Breeze Dark color scheme as
# scripts/screenshots.sh uses it, but in the C.UTF-8 locale, so en_US.UTF-8
# need not be installed. It passes when qml6 exits with 0, the scene reports
# "SCREENSHOTS OK" and the background color of that scheme, prints no
# warning, all files are readable PNG files without metadata, and the
# processor graph and the memory bar of the popup are drawn. This is no review
# of the images; the published ones come from scripts/screenshots.sh.
#
#   LOADRINGS_SCREENSHOT_DIR=$(mktemp -d) tools/screenshots/offscreen-check.sh
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/screenshots/scene.sh
. "$here/scene.sh"

dir="${LOADRINGS_SCREENSHOT_DIR:-}"
if [ -z "$dir" ]; then
  echo "offscreen-check: set LOADRINGS_SCREENSHOT_DIR to the directory for the images" >&2
  exit 2
fi
mkdir -p "$dir" || exit 1
dir="$(cd "$dir" && pwd)"

log="$(mktemp)" || exit 1
trap 'rm -f "$log"' EXIT
config="$(mktemp -d)" || exit 1
trap 'rm -rf "$log" "$config"' EXIT
setup_theme Dark "$config" || exit 1

QT_QPA_PLATFORM=offscreen LANGUAGE=en LC_ALL=C.UTF-8 LANG=C.UTF-8 QT_SCALE_FACTOR=1 run_scene "$dir" "$log" "$config"
rc=$?
output="$(cat "$log")"
unexpected="$(other_lines "$output")$(qml_problems "$output")"
theme="$(theme_problem "$output" "$(window_background "$(breeze_colors Dark)")")"

status=0
if [ "$rc" -ne 0 ] || ! grep -q '^qml: SCREENSHOTS OK$' <<<"$output"; then
  echo "offscreen-check: the scene failed (exit $rc)" >&2
  status=1
fi
if [ -n "$unexpected" ]; then
  echo "offscreen-check: unexpected output:" >&2
  echo "$unexpected" >&2
  status=1
fi
if [ -n "$theme" ]; then
  echo "offscreen-check: $theme" >&2
  status=1
fi
node "$here/check-images.mjs" "$dir" --log "$log" || status=1
exit "$status"
