#!/usr/bin/env bash
#
# Patch the VirtFolder Obsidian plugin so the root and nested virtual folders
# open expanded, while only "Orphans" stays collapsed.
#
# VirtFolder ships pre-compiled JS, so we rewrite `main.js` in place. Obsidian
# auto-updates the plugin from time to time, which silently un-patches us, so
# the umbrella re-runs this on every `chezmoi apply`.
#
# Called by run_after_35-patch-obsidian-plugins.sh — not for direct use.
#
# Args:
#   $1  vault root (absolute path)
set -euo pipefail

VAULT="${1:?vault root required}"
PLUGIN="virt-folder"
EXPECTED_VERSION="1.1.22"
FILE="$VAULT/.obsidian/plugins/$PLUGIN/main.js"
TAG="[virtfolder-expanded]"

[ -f "$FILE" ] || exit 0

source "$(dirname -- "$0")/_lib.sh"
require_plugin_version "$VAULT" "$PLUGIN" "$EXPECTED_VERSION" "$TAG"

ORIGINAL='let isCollapsed = true;'
PATCHED='let isCollapsed = type === "orphan_dir";'

if grep -Fq "$PATCHED" "$FILE"; then
  exit 0
fi

COUNT=$(grep -cF "$ORIGINAL" "$FILE" || true)
if [ "$COUNT" != "1" ]; then
  echo "$TAG ERROR: expected exactly 1 patch target in" >&2
  echo "$TAG   $FILE" >&2
  echo "$TAG   found $COUNT — VirtFolder upstream likely changed." >&2
  exit 1
fi

perl -0pi -e 's/\Qlet isCollapsed = true;\E/let isCollapsed = type === "orphan_dir";/' "$FILE"

if ! grep -Fq "$PATCHED" "$FILE"; then
  echo "$TAG ERROR: patch verification failed for $FILE" >&2
  exit 1
fi

echo "$TAG re-applied default-expanded patch to $FILE"
