#!/usr/bin/env bash
#
# Patch the Spaced Repetition plugin to stop StatisticsPage.renderCharts() from
# pinning a CPU core forever on startup.
#
# Root cause: renderCharts() bails to `sync().then(() => renderCharts())` while
# `osrCore.cardStats` is still unset. The retry fires as a *microtask*, which
# re-runs before the event loop can drain the macrotask/IO work that actually
# populates cardStats. Under a heavy plugin load (cardStats not ready by the
# first call) this becomes a self-defeating busy-poll: it starves the very
# async work it is waiting on -> infinite 100%-one-core livelock, frozen UI.
#
# True trigger (confirmed via a renderCharts stack dump): the *settings-search*
# plugin indexes every plugin's settings on startup by calling each tab's
# display(). SR's display() eagerly builds the StatisticsPage (Chart.js) ->
# renderCharts() -> the loop, long before SR's own onLayoutReady sync() has
# populated cardStats. Other plugins (omnisearch et al.) only tip the startup
# race. None of our chezmoi patches are involved.
#
# Fix: pace the retry through setTimeout (yields to the macrotask queue so the
# pending sync/metadata work can finish and set cardStats) and bound it so a
# genuinely-never-ready state degrades to "no chart" instead of a freeze.
#
# Spaced Repetition ships pre-compiled JS, so we rewrite main.js in place;
# Obsidian's auto-updater silently un-patches us, so the umbrella re-runs this
# on every `chezmoi apply`.
#
# Called by run_after_35-patch-obsidian-plugins.sh — not for direct use.
#
# Args:
#   $1  vault root (absolute path)
set -euo pipefail

VAULT="${1:?vault root required}"
PLUGIN="obsidian-spaced-repetition"
EXPECTED_VERSION="1.15.0"
FILE="$VAULT/.obsidian/plugins/$PLUGIN/main.js"
TAG="[sr-chart-loop]"

[ -f "$FILE" ] || exit 0

source "$(dirname -- "$0")/_lib.sh"
require_plugin_version "$VAULT" "$PLUGIN" "$EXPECTED_VERSION" "$TAG"

ORIGINAL='this.dataManager.sync().then((_2) => this.renderCharts(this.dataManager.osrCore));'
MARKER='_srChartRetries'

# Already patched?
if grep -Fq "$MARKER" "$FILE"; then
  exit 0
fi

COUNT=$(grep -cF "$ORIGINAL" "$FILE" || true)
if [ "$COUNT" != "1" ]; then
  echo "$TAG ERROR: expected exactly 1 patch target in" >&2
  echo "$TAG   $FILE" >&2
  echo "$TAG   found $COUNT — Spaced Repetition upstream likely changed." >&2
  exit 1
fi

perl -0pi -e 's/\Qthis.dataManager.sync().then((_2) => this.renderCharts(this.dataManager.osrCore));\E/this._srChartRetries = (this._srChartRetries || 0) + 1; if (this._srChartRetries > 20) return; this.dataManager.sync().then((_2) => setTimeout(() => this.renderCharts(this.dataManager.osrCore), 120));/' "$FILE"

if ! grep -Fq "$MARKER" "$FILE"; then
  echo "$TAG ERROR: patch verification failed for $FILE" >&2
  exit 1
fi

echo "$TAG re-applied chart-loop fix to $FILE"
