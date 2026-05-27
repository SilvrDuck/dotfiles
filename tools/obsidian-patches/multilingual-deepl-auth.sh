#!/usr/bin/env bash
#
# Apply the functional half of leolazou/obsidian-multilingual PR #3 to the
# plugin's bundled main.js. DeepL deprecated the `auth_key=` query parameter;
# the plugin must instead send the token as `Authorization: DeepL-Auth-Key …`.
# The upstream repo is not actively merging PRs, so we patch in place.
#
# We intentionally only adapt the *functional* edits — the URL constant
# `DEEPL_API_URL` is not modified, so the key still flows only to DeepL.
# Whitespace and style hunks from the PR are ignored to keep the patch
# minimal and the anchors stable.
#
# Upstream: https://github.com/leolazou/obsidian-multilingual/pull/3
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
TAG="[multilingual-deepl-auth]"

[ -f "$FILE" ] || exit 0

source "$(dirname -- "$0")/_lib.sh"
require_plugin_version "$VAULT" "$PLUGIN" "$EXPECTED_VERSION" "$TAG"

# Header-auth migration leaves this distinctive marker; presence = already patched.
if grep -Fq 'DeepL-Auth-Key' "$FILE"; then
  exit 0
fi

python3 - "$FILE" "$TAG" <<'PY'
import sys
import pathlib

path = pathlib.Path(sys.argv[1])
tag = sys.argv[2]
src = path.read_text()

REMOVE_AUTH_KEY_FIND = (
    '      auth_key: this.settings.apiKeys["DeepL"],\n'
    '      text,'
)
REMOVE_AUTH_KEY_REPL = '      text,'

ADD_HEADERS_FIND = (
    '        url: `${DEEPL_API_URL}?${params.toString()}`,\n'
    '        method: "POST",\n'
    '        throw: false'
)
ADD_HEADERS_REPL = (
    '        url: `${DEEPL_API_URL}?${params.toString()}`,\n'
    '        method: "POST",\n'
    '        headers: {\n'
    '          "Authorization": `DeepL-Auth-Key ${this.settings.apiKeys["DeepL"]}`,\n'
    '          "Content-Type": "application/x-www-form-urlencoded"\n'
    '        },\n'
    '        throw: false'
)

for label, anchor in (("remove auth_key", REMOVE_AUTH_KEY_FIND),
                      ("add headers", ADD_HEADERS_FIND)):
    count = src.count(anchor)
    if count != 1:
        sys.stderr.write(
            f"{tag} ERROR: anchor {label!r} matched {count} times in {path}; "
            "expected exactly 1. Upstream likely changed.\n"
        )
        sys.exit(1)

src = src.replace(REMOVE_AUTH_KEY_FIND, REMOVE_AUTH_KEY_REPL, 1)
src = src.replace(ADD_HEADERS_FIND, ADD_HEADERS_REPL, 1)

if "DeepL-Auth-Key" not in src:
    sys.stderr.write(f"{tag} ERROR: post-patch sanity check failed for {path}\n")
    sys.exit(1)

path.write_text(src)
PY

echo "$TAG re-applied DeepL header-auth patch to $FILE"
