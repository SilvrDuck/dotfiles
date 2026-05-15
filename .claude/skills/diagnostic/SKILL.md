---
name: diagnostic
description: Use when the user runs /diagnostic or asks what the chezmoi best-effort install left missing on this machine. Reads expected artifacts from the repo at runtime (`.chezmoidata/packages.yaml`, `.chezmoitemplates/ai-cli-installers.sh`, `dot_config/mise/config.toml`, bootstrap `run_*.tmpl` scripts, manual `scripts/`), probes each one against the active package manager and system state, and reports `ok` / `missing` / `not_run` / `n/a` / `unknown` per item. Proposes the exact fix command per non-ok item without running it.
---

# /diagnostic

Tell the user which expected install artifacts are present on this machine and propose fixes for the rest. Read-only.

## Step 1 — Consult the chezmoi skill

Invoke `Skill(skill="chezmoi")` before any chezmoi command.

## Step 2 — Run the probe

```
bash "${CLAUDE_SKILL_DIR}/scripts/probe.sh"
```

Output is TSV: `category<TAB>name<TAB>status<TAB>note`.
Statuses: `ok` | `missing` | `not_run` | `n/a` | `unknown`.

The probe stays generalist: every check is derived from the repo at runtime, with **no per-package or per-script knowledge inside the script**. Adding a tool to `packages.yaml` or a new file under `scripts/` is picked up without script edits. Do not re-implement the script's logic in conversation; let the TSV speak.

## Step 3 — Resolve `unknown` rows

The probe deliberately emits `unknown` where a generic check would be a guess. Reclassify each one by reading the corresponding source file in the repo:

- **`packages` row with note `manual (<installer_name>)`** — the package is installed by a function in `.chezmoitemplates/apt-manual-installers.sh`, not the apt db. Open that file, find the `install_manual_<installer_name>()` function, read what file or binary it produces, probe for that, and reclassify as `ok` or `missing`.
- **`manual <script>` row** — open the matching file in `scripts/`, identify the post-condition it produces (a file path written, a config key set, a service it loads), probe for that, and reclassify as `ok` or `not_run`.

If the source file doesn't make the post-condition obvious, leave the row `unknown` and quote which lines you read and what was ambiguous.

## Step 4 — Render

Group by category in this order: `packages` → `ai_cli` → `mise` → `bootstrap` → `manual`.
- If every row in a category is `ok`, collapse to one line: `Packages — all N present`.
- Otherwise render a table: `name | status | note`.
- Always surface `unknown` rows. Don't hide them.

## Step 5 — Propose fixes (do not run them)

For each non-`ok`, non-`n/a` row, append the single command that retries it:

- `packages` missing → `chezmoi apply` (re-runs `run_onchange_after_10-packages.sh.tmpl`, which re-attempts every install). For one or two, add the direct fallback for the active manager (`brew install …` / `sudo pacman -S …` / `yay -S …` / `sudo apt-get install …`).
- `ai_cli` missing → quote the exact `curl | bash` line from `.chezmoitemplates/ai-cli-installers.sh` for that CLI.
- `mise` missing → `mise install`.
- `bootstrap login_shell` → `chsh -s "$(command -v zsh)"`.
- `bootstrap gitleaks_hook` → `chezmoi apply` (re-runs the hook script). If `gitleaks` is missing too, install it first.
- `bootstrap yay` → see the makepkg block in `.chezmoitemplates/package-manager-helpers.sh`.
- `manual <script>` not_run → `$(chezmoi source-path)/scripts/<script>`.

If a `packages missing` note says the active manager has no record of the override-resolved name, that may indicate a real bug in `packages.yaml` (wrong override name). Flag it as something to fix in the repo, not just on this machine.

End with: **"Run the proposals above manually — `/diagnostic` does not modify anything."**

## Hard rules

- Read-only. Never install, never `chezmoi apply`, never modify config. Even if the user says "fix it" mid-run, stop and confirm.
- When you reclassify an `unknown` row, say which file you read and what you probed.
- Never `chezmoi add`, commit, or push.
- No new docs, no summary file, no memory writes.
