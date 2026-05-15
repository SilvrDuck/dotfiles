# SilvrDuck's chezmoi config

## What this repo is

Personal chezmoi-managed dotfiles for macOS, pacman/apt Linux, Omarchy, and devcontainers. The working directory is the chezmoi source dir (`chezmoi source-path` resolves here). New machines install via the one-liner in `README.md`.

## Philosophy (load-bearing — read before editing)

The repo is built to stay lean. When making changes, hold these lines:

- **One short README, self-documenting scripts, readable YAML.** No `docs/` folder, no profile-inspection command, no Git wrapper, no `bootstrap.sh`. If you're tempted to add documentation files, push the explanation into a code/script comment or the README instead. ALWAYS ask the user before adding any doc, but feel free to propose.
- **One source of truth per concern.** Packages live only in `.chezmoidata/packages.yaml`. Machine differences live only in `.chezmoi.toml.tmpl`. Don't duplicate.
- **Best-effort install.** Package install failures `echo skipped` and continue — never `set -e` away from that. The AI CLI installers (`claude`, `opencode`, `pi`) intentionally `curl | bash` from upstream; this is called out in the script and is deliberate.
- **No install toggles beyond `machine_kind`.** The kinds (`desktop` / `omarchy` / `devcontainer`) are mostly template context. Resist adding feature flags / optional groups.
- **Secrets are local-only, unencrypted, per-machine.** They live at `~/.config/dotfiles/secrets/env.d/*.zsh` (chmod 600), populated by `scripts/setup-api-keys`. Do NOT add chezmoi encryption for API keys.
- **`scripts/` is repo-only, not installed.** It's listed in `.chezmoiignore.tmpl` and run manually from paths in the README. Do not add it to `$PATH` or move it under `dot_*`. Scripts are all interactive and minimal, self-documenting.
- **Omarchy owns its default files; we own the local overrides via chezmoi.** Anything we customize on top of an Omarchy default (hypr, waybar, swayosd, custom themes/extensions/hooks, terminals, etc.) is tracked here. Leave files we don't override alone — `omarchy refresh` / `omarchy update` keep them current. By default these overrides apply on every machine, so other kinds benefit too. Only guard with `{{ if .is_omarchy_detected }}` (or `.chezmoiignore.tmpl`) when a tweak is specifically *needed* for Omarchy — e.g., working around an Omarchy quirk or referencing an Omarchy-only path. There may not be any such cases.
- **No line of config that only restates the default.** Override only what you're actually changing — every key in an `opts` block must be doing real work. Defaults are the favorite; they survive upgrades, they document themselves, and they keep diffs honest.
- **Always research online before touching any tool's config.** Fetch the upstream docs (WebFetch / context7) to confirm current option names, defaults, and feel. No going from memory — option schemas drift, and "I think the default is X" leads to redundant or stale config lines. Quote the default you found so the user can sanity-check.

## Apply / iterate

ALWAYS consult your chezmoi skill. Be extremely question forward. Any doubt, ask the user. The user wants lean no bullshit, standard stuff. If you have to do convoluted stuff to satisfy a user request, let them know and ask for guidance.

After editing source files, proactively offer to run the lifecycle for the user: `chezmoi diff` (dry-run preview), then `chezmoi apply`, then a git commit with a sensible message, then `git push`. Ask once before kicking it off; don't run them silently. Always follow each add/commit round with a push.

Before asking to commit, run `git diff` (and `git diff --staged` if anything is staged) and summarize it in 1–3 lines — files touched + what changed — so the user can approve without opening the diff themselves. `git diff` / `git status` / `git log` are pre-approved in `.claude/settings.json`; commits, pushes, and anything mutating still prompt.

**Do not add `Co-Authored-By: Claude …` (or any Claude attribution trailer) to commits in this repo.** Plain commit messages only.

If the working tree has dirty files or untracked paths you didn't touch, proactively flag them and ask whether to include them in the commit before staging. Don't silently bundle, and don't silently leave them behind — surface the choice.

**Public-internet audit before EVERY commit — mandatory, no exceptions.** This repo is published. Before staging anything, scan the full diff for: PII (name, email, employer, machine hostnames, `/home/<user>` paths, MAC/IP addresses), credentials of any form, internal/private URLs, machine-specific values, and *soft disclosures* — app/service preferences, regional hints, employer hints, anything that profiles the user. List every concrete finding in plain prose and get **explicit per-item approval from the user** before committing — no batched "looks fine?", no implicit consent, no "this seems harmless so I'll include it". Gitleaks catches credential patterns as a backstop; it does NOT catch soft disclosures. Manual review is the primary gate, gitleaks is the second.

## Architecture

Bootstrap chain (numeric prefix = order):

1. `run_once_before_00-prereqs.sh.tmpl` — installs Homebrew on macOS or ensures git/curl/build-essential on Linux. Detects pacman vs apt.
2. `run_onchange_after_10-packages.sh.tmpl` — iterates `.chezmoidata/packages.yaml` groups (`core`, `shell`, `cli`, `desktop`, `nvim`) and installs via brew / pacman / yay (AUR) / apt. The per-tool `overrides:` map handles cross-manager name/kind differences (`darwin_kind: cask`, `pacman_aur: …`, `apt_manual: antidote_git`). The same script then installs `claude`, `opencode`, `pi` from upstream — intentional.
3. `run_onchange_after_15-mise-install.sh.tmpl` — runs `mise install` whenever `dot_config/mise/config.toml` changes.
4. `run_onchange_after_20-gitleaks-hook.sh.tmpl` — writes a `pre-commit` hook into THIS repo's `.git/hooks/` that runs `gitleaks` with `.gitleaks.toml`. Commits here require `gitleaks` on PATH.

Templates branch on `.machine_kind` and `.is_mac` / `.is_linux` / `.is_omarchy_detected`, all set by `.chezmoi.toml.tmpl`.

`scripts/` (manual, not on PATH; paths in `README.md`):
- `setup-git-default-context` — boring default identity + one SSH key + include `git-defaults`. No URL rewrites.
- `setup-git-additional-context` — work/client identity: `includeIf` for a folder + dedicated SSH key + `Host github.com-<ctx>` aliases + `url.…insteadOf` rewrites for known org prefixes.
- `setup-api-keys` — writes `~/.config/dotfiles/secrets/env.d/*.zsh` (sourced from `dot_zshrc.tmpl`).
- `setup-keyboard-layout` — keyboard config.

## Shell stack (touch with care — load order is the bug source)

`zsh` + Antidote + Starship + native vi mode + zsh-autosuggestions + fzf-tab + fast-syntax-highlighting + zsh-completions + Carapace + fzf + zoxide-as-`z`.

Strict load order in `dot_zshrc.tmpl` — do not reorder:

1. add `zsh-completions` to `fpath` via `dot_zsh_plugins_fpath.txt`
2. set `zstyle` completion styles
3. `compinit`
4. Carapace
5. `fzf-tab` + widget-wrappers via `dot_zsh_plugins_after_compinit.txt`

Universal escape is `jk` / `kj` — shell vi insert, nvim insert, nvim terminal, AND nvim visual/select. Keep these bindings in sync.

Explicitly NOT in the stack: `zsh-autocomplete`, `zsh-vi-mode` plugin, Atuin, yazi-in-core. Don't reintroduce them without a strong reason.

## Adding things

- **New package:** add to one group in `.chezmoidata/packages.yaml`. Only add an `overrides:` entry if a manager uses a different name or install kind. The file-hash comment in `run_onchange_after_10-packages.sh.tmpl` re-triggers install on next apply.
- **Python project work:** `mise` manages Python versions, `uv` manages project envs. `pyenv` is not installed and should not be added.
- **Editing templates:** always preview with `chezmoi execute-template` or `chezmoi diff` before `apply`. Bootstrap scripts use `|| true` / `echo skipped` to survive partial environments (e.g., devcontainers without yay) — preserve that.

