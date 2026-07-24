#!/usr/bin/env bash
# probe.sh — diagnose what the best-effort install produced on this machine.
#
# Generalist by design: every check is derived from repo state at runtime
# (.chezmoidata/packages.yaml, .chezmoitemplates/upstream-installers.sh,
# the mise-install script's heredoc, run_*.tmpl bootstrap scripts, scripts/). No
# per-package or per-script knowledge is encoded here — adding a tool to
# packages.yaml or a new script under scripts/ is picked up automatically.
#
# Output: TSV  category<TAB>name<TAB>status<TAB>note
# Statuses: ok | missing | not_run | n/a | unknown
# Best-effort: never exits non-zero. Whatever can't be probed -> unknown.

set -u
LC_ALL=C
IFS=$'\n\t'

SKILL_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
REPO="$(chezmoi source-path 2>/dev/null || { cd "$SKILL_DIR/../../../.." && pwd; })"
PKG_YAML="$REPO/.chezmoidata/packages.yaml"
# mise's [tools] baseline lives in the install script's heredoc, not a tracked
# config file — mise rewrites ~/.config/mise/config.toml, so it is unmanaged.
MISE_CFG="$REPO/run_onchange_after_15-mise-install.sh.tmpl"
AI_INSTALLER="$REPO/.chezmoitemplates/upstream-installers.sh"
SCRIPTS_DIR="$REPO/scripts"

emit() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${4:-}"; }
has()  { command -v "$1" >/dev/null 2>&1; }

# Pick the active package manager (one per host in practice).
if   has brew;    then MGR=brew
elif has pacman;  then MGR=pacman
elif has apt-get; then MGR=apt
else                   MGR=""
fi

# manager_has <mgr> <name>: does the active package manager report this name
# as installed? This is the source of truth — it transparently covers fonts,
# system packages, libraries, and AUR-via-yay (which lands in the pacman db).
manager_has() {
  case "$1" in
    pacman) pacman -Qq "$2" >/dev/null 2>&1 ;;
    brew)   brew list "$2" >/dev/null 2>&1 ;;
    apt)    dpkg-query -W -f='${Status}' "$2" 2>/dev/null \
              | grep -q 'install ok installed' ;;
    *) return 1 ;;
  esac
}

# ---- packages ----
# One yq pass emits each yaml key plus its full override row. Bash picks the
# right install name for the active manager and queries it.
if [ ! -r "$PKG_YAML" ]; then
  emit packages '*' unknown "no $PKG_YAML"
elif ! has yq; then
  emit packages '*' unknown "yq not on PATH; cannot parse $PKG_YAML"
elif [ -z "$MGR" ]; then
  emit packages '*' unknown "no supported package manager on this host"
else
  # Optional packages are opt-in per machine; an unchosen one is not "missing".
  optional_keys=" $(yq -r '.packages.optional[].packages[]' "$PKG_YAML" 2>/dev/null | tr '\n' ' ') "
  choices="$HOME/.config/dotfiles/package-choices"

  # Pipe-delimit because read collapses consecutive whitespace IFS chars
  # (including \t), which would drop empty override fields.
  yq -r '
    .packages as $p
    | ($p.baseline[][], $p.optional[].packages[]) as $key
    | ($p.overrides[$key] // {}) as $o
    | [
        $key,
        ($o.pacman     // ""),
        ($o.pacman_aur // ""),
        ($o.darwin     // ""),
        ($o.apt        // ""),
        ($o.apt_manual // "")
      ] | join("|")
  ' "$PKG_YAML" | while IFS='|' read -r key pac aur drv apt_name manual; do
    # Opt-in package not chosen on this machine -> not expected, not missing.
    case " $optional_keys " in
      *" $key "*)
        grep -qxF "$key=1" "$choices" 2>/dev/null || {
          emit packages "$key" "n/a" "optional; not opted in on this machine"
          continue
        } ;;
    esac
    case "$MGR" in
      # AUR packages surface in the pacman db, so $aur is a valid fallback.
      pacman) name="${pac:-${aur:-$key}}" ;;
      brew)   name="${drv:-$key}" ;;
      apt)
        if [ -n "$manual" ]; then
          # Installed by a function in .chezmoitemplates/apt-manual-installers.sh;
          # not in the apt db. Fall back to checking for a binary matching the
          # yaml key — generic, no per-package mapping.
          if has "$key"; then
            emit packages "$key" ok "manual ($manual): '$key' on PATH"
          else
            emit packages "$key" unknown "manual ($manual): no '$key' on PATH; read installer to verify"
          fi
          continue
        fi
        name="${apt_name:-$key}" ;;
    esac
    if manager_has "$MGR" "$name"; then
      emit packages "$key" ok
    else
      emit packages "$key" missing "$MGR has no record of '$name'"
    fi
  done
fi

# ---- AI CLIs ----
# Source of truth: the installer file. Two patterns identify a CLI it actually
# installs (vs. a dep it merely checks for):
#   1) `command -v X … || (curl|wget|brew|npm) …` — inline install guard
#   2) `install_X` at column 0 — function-wrapped install call
# Dep checks use `if command -v X ...; then …` and won't match either pattern.
if [ -r "$AI_INSTALLER" ]; then
  {
    grep -oE 'command -v [a-z][a-z0-9_-]+[^|]*\|\|[[:space:]]+(curl|wget|brew|npm)' \
         "$AI_INSTALLER" | awk '{print $3}'
    grep -oE '^install_[a-z][a-z0-9_-]+' "$AI_INSTALLER" | sed 's/^install_//'
  } | sort -u | while read -r cli; do
    [ -n "$cli" ] || continue
    has "$cli" \
      && emit ai_cli "$cli" ok \
      || emit ai_cli "$cli" missing "not on PATH"
  done
else
  emit ai_cli '*' unknown "no $AI_INSTALLER to enumerate AI CLIs"
fi

# ---- mise runtimes ----
if has mise; then
  if [ -r "$MISE_CFG" ]; then
    expected=$(awk '
      /^\[tools\]/  { in_tools=1; next }
      /^\[/         { in_tools=0 }
      in_tools && /^[a-zA-Z0-9_.-]+[[:space:]]*=/ { sub(/[[:space:]]*=.*/, ""); print }
    ' "$MISE_CFG")
    installed=$(mise ls --current 2>/dev/null | awk '{print $1}' | sort -u)
    if [ -z "$expected" ]; then
      emit mise '*' n/a "no [tools] entries in mise config"
    else
      for tool in $expected; do
        if printf '%s\n' "$installed" | grep -qx "$tool"; then
          emit mise "$tool" ok
        else
          emit mise "$tool" missing "mise has not installed this runtime"
        fi
      done
    fi
  else
    emit mise '*' unknown "no $MISE_CFG"
  fi
else
  emit mise '*' missing "mise not installed"
fi

# ---- bootstrap ----
# These checks correspond 1:1 to the run_*.tmpl bootstrap scripts in the repo
# root. If a new bootstrap script is added with a post-condition worth probing,
# it goes here — but the set is small and stable enough to enumerate.

# Login shell flip happens in run_onchange_after_10-packages.sh.tmpl (Linux).
if [ "$(uname -s)" = Linux ]; then
  shell=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)
  if [ "${shell##*/}" = zsh ]; then
    emit bootstrap login_shell ok "$shell"
  else
    emit bootstrap login_shell missing "current: ${shell:-?}; expected zsh"
  fi
else
  emit bootstrap login_shell n/a "Linux-only check"
fi

# AUR helper required when pacman is active and any yaml entry needs AUR.
if [ "$MGR" = pacman ] && grep -q pacman_aur "$PKG_YAML" 2>/dev/null; then
  has yay \
    && emit bootstrap yay ok \
    || emit bootstrap yay missing "AUR packages will not install without yay"
else
  emit bootstrap yay n/a
fi

# Gitleaks pre-commit hook installed by run_onchange_after_20-gitleaks-hook.sh.tmpl
hook="$REPO/.git/hooks/pre-commit"
if [ -x "$hook" ] && has gitleaks; then
  emit bootstrap gitleaks_hook ok
elif [ ! -x "$hook" ]; then
  emit bootstrap gitleaks_hook missing "no executable .git/hooks/pre-commit"
else
  emit bootstrap gitleaks_hook missing "hook present but gitleaks not on PATH"
fi

# ---- manual scripts ----
# Enumerate scripts/ — don't try to detect "did it run" generically. Each
# script's post-condition lives in the script itself; the SKILL.md tells the
# LLM to read it and probe inline when reclassifying `unknown` rows.
if [ -d "$SCRIPTS_DIR" ]; then
  for path in "$SCRIPTS_DIR"/*; do
    [ -f "$path" ] || continue
    name=${path##*/}
    case "$name" in .*|*.md|README*) continue ;; esac
    emit manual "$name" unknown "read $path to derive a post-condition check"
  done
else
  emit manual '*' unknown "no $SCRIPTS_DIR directory"
fi
