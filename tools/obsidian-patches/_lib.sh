#!/usr/bin/env bash
#
# Shared helpers for Obsidian-plugin patch subscripts in this directory.
# Filenames starting with `_` are skipped by the umbrella loop, so this
# file is never run directly — it is sourced from each subscript:
#
#   source "$(dirname "$0")/_lib.sh"
#
# Provides:
#   require_plugin_version <vault> <plugin-id> <expected-version> <tag>
#     Loudly aborts (exit 1) when the installed plugin's manifest version
#     differs from the version a patch was authored against. Silent no-op
#     when the plugin (or its manifest) isn't installed — that case is
#     normally short-circuited by the caller's own file-existence check.
#
# The version pin is the contract: any drift forces a human re-audit of
# the bundled JS before we touch it, since identical-looking anchors in
# a newer bundle may carry different semantics.

require_plugin_version() {
  local vault="${1:?vault required}"
  local plugin="${2:?plugin id required}"
  local expected="${3:?expected version required}"
  local tag="${4:?tag required}"
  local manifest="$vault/.obsidian/plugins/$plugin/manifest.json"

  [ -f "$manifest" ] || return 0

  local actual=""
  actual=$(jq -r '.version // ""' < "$manifest" 2>/dev/null || true)

  if [ "$actual" != "$expected" ]; then
    cat >&2 <<EOF
$tag ERROR: plugin '$plugin' version drift detected.
$tag   expected:  $expected  (the version this patch was authored against)
$tag   installed: ${actual:-<unreadable>}
$tag   The bundled JS likely changed shape. Re-audit the patch against
$tag   the new bundle, update the version pin in the subscript, then
$tag   re-run chezmoi apply.
EOF
    exit 1
  fi
}
