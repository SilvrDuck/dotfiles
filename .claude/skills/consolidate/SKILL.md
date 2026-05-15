---
name: consolidate
description: Use when the user runs /consolidate or asks to reconcile local machine state with this chezmoi repo. Surfaces four buckets — tracked drift, untracked candidates, package drift, and stale source items — with cross-platform impact, and presents per-item choices the user walks one at a time. Never batch-decides. Includes a mandatory public-internet audit step because this repo is public, and a sanitized memory-write step at the end.
---

You are running inside this chezmoi source repo. Goal: surface everything the user did locally on the **current machine** that should propagate to the other kinds (`desktop` / `omarchy` / `devcontainer`, mac and linux), so a `git push` + `chezmoi apply` elsewhere replicates the state. **Never decide for the user** — present a list, recommend, but let them choose every item.

## Step 0 — Privacy gate (mandatory, do not skip)

This repo is **public on the internet**. Before scanning or acting, restate the public-internet audit rule from `CLAUDE.md` **in your own words, in 3-5 lines**, covering the categories you will flag:

- PII (name, email, employer, machine hostnames, `/home/<user>` paths, MAC/IP addresses)
- Credentials of any form
- Internal / private URLs
- Machine-specific values
- **Soft disclosures** — app/service preferences, regional hints, employer hints, anything that profiles the user (gitleaks does NOT catch these)

Tell the user you will flag findings **per item** and require **explicit per-item approval** before staging — no batched "looks fine?", no implicit consent. **And: the same sanitization rule applies to anything you write to memory (Step 7) — treat the memory body as if it will end up on the public internet, even though by default it stays local.** Then proceed.

## Step 1 — Consult the chezmoi skill

Per `CLAUDE.md`, always consult the chezmoi skill before non-trivial chezmoi work. Invoke it now via `Skill(skill="chezmoi")` to ground command syntax against the current chezmoi version.

## Step 2 — Detect machine kind

Read `.chezmoi.toml.tmpl` (or run `chezmoi data | jq '{machine_kind, is_mac, is_linux, is_omarchy_detected}'`) to know which platform you are on. Every cross-platform claim below depends on this.

## Step 3 — Scan (read-only, batch in parallel where safe)

Produce four buckets:

### A. Tracked drift — source vs. live target diverge
- `chezmoi status` (M/A/D flags)
- `chezmoi diff` for content
- For each entry: decide whether the **live file** is the new truth (promote) or **source** is (revert).

### B. Untracked candidates — live config not in chezmoi
- `chezmoi managed` → set of tracked targets
- Walk likely dotfile locations on this platform: `~/.config/*`, `~/.zshrc*`, `~/.gitconfig*`, `~/.ssh/config`, `~/Library/Application Support/*` (mac), `~/.local/share/applications/`, etc.
- Restrict to recently-modified files (mtime within the last ~60 days) to keep the list signal-rich.
- Subtract anything already managed or already in `.chezmoiignore.tmpl`.

### C. Package drift — installed but not in `.chezmoidata/packages.yaml`

```
bash "${CLAUDE_SKILL_DIR}/scripts/package-drift.sh"
```

Emits TSV `manager<TAB>name` for every explicit install on this machine that isn't accounted for by `packages.yaml` (the script reads `.packages.groups` and resolves every per-manager override — `pacman`, `pacman_aur`, `darwin`, `apt` — so the diff respects renames).

Filter out obvious system / transitive packages — only surface things a human would intentionally install. The script only probes managers that are present on the host.

### D. Stale items — in source but not real anywhere
- yaml entries with no install on **any** installed manager you can check
- template branches whose condition is permanently false
- `.chezmoiignore.tmpl` lines matching nothing
- `overrides:` keys for groups that no longer exist
- comments referencing removed scripts / paths

## Step 4 — Cross-platform research (required for each candidate change)

Before suggesting promotion of **any** candidate, do the research — `CLAUDE.md` explicitly forbids going from memory:

- **Package**: confirm the name on every manager that this repo supports (pacman, AUR, brew, apt). Use `brew info <pkg>`, `pacman -Si`, `apt-cache show`, or `WebFetch` / `mcp__claude_ai_Context7__query-docs` for upstream docs. Propose the exact yaml entry — including `overrides:` only if a manager actually differs.
- **Config file**: confirm the tool exists and behaves the same on the other platforms. Note real path differences (`/opt/homebrew` vs `/usr/local`, XDG vs `~/Library`). Suggest `.tmpl` + `{{ if .is_mac }}` / `{{ if .is_omarchy_detected }}` **only when a real difference exists** — never to "future-proof".
- **Config option**: fetch upstream docs to confirm option name, default, and version. **Quote the default you found** so the user can sanity-check. If a line only restates the default, drop it (philosophy: "No line of config that only restates the default").

If research is inconclusive, say so out loud — do not pretend.

## Step 5 — Present (numbered, grouped, with recommendation)

Render one combined numbered list, grouped A/B/C/D. For each item show:

1. **What** — concrete path / package / yaml line
2. **Privacy flag** — `clean` / `⚠ <category>` (must call this out item-by-item, not in aggregate)
3. **Cross-platform note** — works on all three / needs templating / Linux-only / etc.
4. **Options** — usually three, e.g. for drift: `(a) revert local (chezmoi apply)`, `(b) promote local (chezmoi re-add)`, `(c) skip`. For untracked: `(a) chezmoi add`, `(b) chezmoi add as .tmpl with <gating>`, `(c) ignore (.chezmoiignore.tmpl)`, `(d) skip`.
5. **Recommendation** — one of the options, with a one-line reason

End by listing every `⚠`-flagged item separately and asking the user to approve / redact / drop **each one individually** before anything is staged.

## Step 6 — Wait for user choice, then act narrowly

Stop. Let the user walk the list. Accept per-item picks or grouped picks (`"all A: recommended"`, `"skip all C"`). For anything ambiguous, ask before acting. Apply only what the user chose.

Then run the standard lifecycle from `CLAUDE.md`:
- `chezmoi diff` (preview)
- `chezmoi apply` only if the user picked revert actions
- `git diff` + `git diff --staged` → summarize in 1-3 lines
- Re-run the public-internet audit on the final staged diff, **per item**, get approval
- Commit with a sensible message → push

## Step 7 — Record non-obvious decisions to memory (sanitized)

After the user has chosen, save **1-3 short memories** for any decision that is non-obvious, surprising, or load-bearing for future runs. Save into the auto-memory system under the appropriate type (usually `feedback` or `project`). Follow the two-step process (file + `MEMORY.md` index line).

**Sanitization rule — absolute, no exceptions.** Memory bodies must be safe as if they were already public. The *reason* for a decision is often the most sensitive part. So:

- If the decision is driven by **anything sensitive whatsoever** — PII, credentials, hosts, employer, location, app preferences, soft disclosures of any kind — write the reason as exactly this string and **nothing more**:

  > **Reason:** sensitive — ask the user before re-litigating.

- Do not categorize. Do not hint. Do not say "employer-specific", "VPN-related", "regional", "machine-specific values", etc. — those phrases are themselves leaks. The fixed phrase above is the entire reason field.

- Only when the reason is **provably non-sensitive** (e.g. "upstream default flipped in v2.3 so the explicit line is now load-bearing"), write the actual reason. When in doubt: assume sensitive and use the fixed phrase.

Examples:

| Decision (memory body) | Reason line |
|---|---|
| skipped tracking `~/.config/foo` | **Reason:** sensitive — ask the user before re-litigating. |
| did not gate `bar` with `.is_mac` | **Reason:** upstream confirms identical behavior on darwin/linux as of v1.8. |
| promoted `baz` to source despite looking redundant | **Reason:** sensitive — ask the user before re-litigating. |

Before saving each file: **read your own draft once with the public-internet lens** — would you be comfortable if this exact text showed up on this repo's GitHub page tomorrow? If no, rewrite using the fixed phrase. If still no, do not save.

## Hard rules

- Lean, no bullshit. No new docs. Push explanation into commit messages and code comments.
- One source of truth per concern: packages only in `.chezmoidata/packages.yaml`; machine differences only in `.chezmoi.toml.tmpl`.
- Best-effort install — keep `|| true` / `echo skipped` patterns.
- Never `chezmoi add` something containing secrets — those live in `~/.config/dotfiles/secrets/env.d/*.zsh`, populated by `scripts/setup-api-keys`, and stay out of chezmoi.
- If you're tempted to take a decisive action "to be helpful": stop and ask.
