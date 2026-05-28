#!/usr/bin/env bash
#
# Extend leolazou/obsidian-multilingual's "Custom path to ignore" setting
# to accept a comma-separated list of folders instead of a single one,
# and anchor the prefix match on a directory boundary so a single name
# like "Templates" no longer accidentally matches "TemplatesArchive/…".
#
# Settings UX after this patch: enter `Templates, Inbox, Archive` (the
# field is the existing single-line input; the upstream description
# string still says "this folder" — semantics is widened to "any of
# these folders").
#
# Backward-compatible: a single existing entry still works unchanged.
#
# Upstream is not actively merging PRs, so we patch the bundle in place.
#
# Called by run_after_35-patch-obsidian-plugins.sh — not for direct use.
#
# Args:
#   $1  vault root (absolute path)
set -euo pipefail

VAULT="${1:?vault root required}"
PLUGIN="multilingual"
EXPECTED_VERSION="1.0.0"
FILE="$VAULT/.obsidian/plugins/$PLUGIN/main.js"
TAG="[multilingual-multi-ignore-path]"

[ -f "$FILE" ] || exit 0

source "$(dirname -- "$0")/_lib.sh"
require_plugin_version "$VAULT" "$PLUGIN" "$EXPECTED_VERSION" "$TAG"

# Distinctive marker that only exists post-patch.
if grep -Fq 'path.startsWith(p + "/")' "$FILE"; then
  exit 0
fi

python3 - "$FILE" "$TAG" <<'PY'
import sys
import pathlib

path = pathlib.Path(sys.argv[1])
tag = sys.argv[2]
src = path.read_text()

FIND = (
    '    const matchesPathToIgnore = !!this.settings.ignorePath '
    '&& path.startsWith(this.settings.ignorePath);'
)
REPL = (
    '    const matchesPathToIgnore = !!this.settings.ignorePath '
    '&& this.settings.ignorePath.split(",")'
    '.map(p => p.trim().replace(/\\/+$/, ""))'
    '.filter(Boolean)'
    '.some(p => path === p || path.startsWith(p + "/"));'
)

count = src.count(FIND)
if count != 1:
    sys.stderr.write(
        f"{tag} ERROR: anchor matched {count} times in {path}; "
        "expected exactly 1. Upstream likely changed.\n"
    )
    sys.exit(1)

src = src.replace(FIND, REPL, 1)

if 'path.startsWith(p + "/")' not in src:
    sys.stderr.write(f"{tag} ERROR: post-patch sanity check failed for {path}\n")
    sys.exit(1)

path.write_text(src)
PY

echo "$TAG re-applied multi-folder ignore-path patch to $FILE"
