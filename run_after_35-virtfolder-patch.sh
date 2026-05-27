#!/usr/bin/env bash
#
# Patch the VirtFolder Obsidian plugin so the root and nested virtual folders
# open expanded, while only "Orphans" stays collapsed.
#
# VirtFolder ships pre-compiled JS, so we rewrite `main.js` in place. Obsidian
# auto-updates the plugin from time to time, which silently un-patches us, so
# this script runs on every `chezmoi apply` and re-asserts the patch.
#
# Behavior:
#   - vault or plugin absent ............. silent no-op
#   - already patched .................... silent no-op
#   - patch applied (after plugin update). one-line notice
#   - patch target missing (upstream code shifted) ..... loud error, exit 1
#
# Override the vault location with OBSIDIAN_VAULT=/path/to/vault.
set -euo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/vaults/main}"
FILE="$VAULT/.obsidian/plugins/virt-folder/main.js"

[ -f "$FILE" ] || exit 0

ORIGINAL='let isCollapsed = true;'
PATCHED='let isCollapsed = type === "orphan_dir";'

if grep -Fq "$PATCHED" "$FILE"; then
  exit 0
fi

COUNT=$(grep -cF "$ORIGINAL" "$FILE" || true)
if [ "$COUNT" != "1" ]; then
  echo "[virtfolder-patch] ERROR: expected exactly 1 patch target in" >&2
  echo "                   $FILE" >&2
  echo "                   found $COUNT — VirtFolder upstream likely changed." >&2
  echo "                   Revisit run_after_35-virtfolder-patch.sh." >&2
  exit 1
fi

perl -0pi -e 's/\Qlet isCollapsed = true;\E/let isCollapsed = type === "orphan_dir";/' "$FILE"

if ! grep -Fq "$PATCHED" "$FILE"; then
  echo "[virtfolder-patch] ERROR: patch verification failed for $FILE" >&2
  exit 1
fi

echo "[virtfolder-patch] re-applied default-expanded patch to $FILE"
