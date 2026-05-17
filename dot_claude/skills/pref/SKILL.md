---
name: pref
description: >
  Save a vihelp / vim style preference. Use when the user types `/pref <text>`
  or asks to remember a vim/nvim style preference. Appends one JSON line to
  ~/.config/vihelp/prefs.jsonl — single file, append-only, git union-merged
  across machines so concurrent saves from different machines don't conflict.
  Loaded by the vihelp persona at session start.
---

# pref — save a vim/vihelp style preference

Append the user's preference as one JSON line to a shared, conflict-free log.

## Storage model

- **File**: `~/.config/vihelp/prefs.jsonl` — one JSON object per line.
- **Schema**: `{"saved":"<YYYY-MM-DD>","text":"<full pref text>"}`. Nothing
  else. Filename and timestamp are the only metadata.
- **Concurrency**: the chezmoi repo has `dot_config/vihelp/prefs.jsonl
  merge=union` in `.gitattributes`, so when two machines both append, git
  merges by keeping all lines from both sides. Never edit an existing line
  during a `/pref` invocation — that breaks the union-merge guarantee.

## Extracting the preference text

The user invoked via `/pref <text>` or natural language. Take `<text>`
verbatim — don't paraphrase, don't reformat. If the invocation has no
text after `/pref`, ask once what to save and stop.

## Steps

1. **Build the JSON line** with proper escaping:
   ```
   {"saved":"<YYYY-MM-DD>","text":"<escaped pref text>"}
   ```
   Use `jq -nc --arg s "<pref text>" '{saved:"<YYYY-MM-DD>",text:$s}'` to
   build it safely — `jq` handles `"`, `\`, and newline escaping correctly.

2. **Dedup check** — if `~/.config/vihelp/prefs.jsonl` already contains a
   line whose `text` field equals the new pref text exactly, do nothing
   and confirm "already saved". Don't append a duplicate. Check with:
   ```
   jq -e --arg s "<pref text>" 'select(.text == $s)' ~/.config/vihelp/prefs.jsonl
   ```
   (Exit 0 → already present; exit 1 → not present, proceed to append.)

3. **Append atomically** to the runtime file:
   ```
   mkdir -p ~/.config/vihelp
   echo '<json line>' >> ~/.config/vihelp/prefs.jsonl
   ```
   `>>` is atomic for short writes on POSIX — safe even if another process
   appends at the same moment.

4. **Mirror into the chezmoi source** so the file is versionable:
   ```
   chezmoi add ~/.config/vihelp/prefs.jsonl
   ```
   This copies the runtime file into
   `$(chezmoi source-path)/dot_config/vihelp/prefs.jsonl`. The runtime
   copy is what vihelp reads at session start; the source copy is what
   git tracks and what gets merged across machines.

5. **Confirm** in two lines. Print the runtime path and the commit command
   the user should run when they're ready to persist across machines:
   ```
   appended → ~/.config/vihelp/prefs.jsonl
   persist: chezmoi cd && git add dot_config/vihelp/prefs.jsonl && git commit
   ```
   Don't run the git commands yourself — this user always reviews commits.

## Hard rules

- **Verbatim text.** Don't rewrite to "sound better." The wording is the
  signal.
- **No critique.** Don't tell the user their preference is suboptimal.
- **Append-only.** Never rewrite or reorder existing lines during `/pref` —
  that breaks `merge=union`. If the user wants to delete or edit a pref,
  they open the file in nvim and edit directly; that's their call.
- **One pref per invocation.** If the input contains several distinct
  preferences, ask the user to split them and re-invoke.
- **Don't touch other files** — no edits to the vihelp persona, the
  `vim-config` skill, or anything else. Prefs are a separate layer
  loaded over those at session start.
