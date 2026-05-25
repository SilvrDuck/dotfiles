#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Fleet
# @raycast.mode silent
# @raycast.packageName Vault
# @raycast.icon 📝
# @raycast.description Capture a fleeting note into the Obsidian vault.
# @raycast.argument1 { "type": "text", "placeholder": "note text" }

exec "$HOME/.local/bin/fleet" "$1"
