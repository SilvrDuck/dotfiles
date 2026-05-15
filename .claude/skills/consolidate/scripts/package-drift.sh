#!/usr/bin/env bash
# package-drift.sh — list explicit installs on this machine that aren't in
# .chezmoidata/packages.yaml. Output TSV: manager<TAB>name
# Only queries managers that are present. Honors per-manager overrides
# (`pacman`, `pacman_aur`, `darwin`, `apt`) so installed names are compared
# against the right key.

set -u
LC_ALL=C
IFS=$'\n\t'

SKILL_DIR="$(cd "${BASH_SOURCE%/*}" && pwd)"
REPO="$(chezmoi source-path 2>/dev/null || { cd "$SKILL_DIR/../../../.." && pwd; })"
PKG_YAML="$REPO/.chezmoidata/packages.yaml"

has() { command -v "$1" >/dev/null 2>&1; }

if ! has yq; then
  echo "package-drift.sh: yq required but missing" >&2
  exit 1
fi

# Build per-manager expected name sets. A package falls back to its yaml key
# when no manager-specific override exists.
expected_pacman=$(mktemp); expected_aur=$(mktemp)
expected_brew=$(mktemp);   expected_apt=$(mktemp)
trap 'rm -f "$expected_pacman" "$expected_aur" "$expected_brew" "$expected_apt"' EXIT

yq -r '
  .packages.groups[][] as $tool
  | (.packages.overrides[$tool] // {}) as $o
  | [
      (($o.pacman     // $tool) + "\tpacman"),
      (($o.pacman_aur // ""   ) + "\taur"),
      (($o.darwin     // $tool) + "\tbrew"),
      (($o.apt        // $tool) + "\tapt")
    ]
  | .[]
' "$PKG_YAML" | while IFS=$'\t' read -r name kind; do
  [ -n "$name" ] || continue
  case "$kind" in
    pacman) printf '%s\n' "$name" >> "$expected_pacman" ;;
    aur)    printf '%s\n' "$name" >> "$expected_aur" ;;
    brew)   printf '%s\n' "$name" >> "$expected_brew" ;;
    apt)    printf '%s\n' "$name" >> "$expected_apt" ;;
  esac
done

# Diff each active manager. -Qenq = explicit + native (excludes AUR);
# -Qmq = foreign (AUR/local) — keeps the two streams clean.
if has pacman; then
  comm -23 <(pacman -Qenq 2>/dev/null | sort -u) <(sort -u "$expected_pacman") \
    | awk '{ printf "pacman\t%s\n", $1 }'
  comm -23 <(pacman -Qmq  2>/dev/null | sort -u) <(sort -u "$expected_aur") \
    | awk '{ printf "aur\t%s\n", $1 }'
fi

if has brew; then
  { brew leaves 2>/dev/null; brew list --cask 2>/dev/null; } \
    | sort -u \
    | comm -23 - <(sort -u "$expected_brew") \
    | awk '{ printf "brew\t%s\n", $1 }'
fi

if has apt-mark; then
  comm -23 <(apt-mark showmanual 2>/dev/null | sort -u) <(sort -u "$expected_apt") \
    | awk '{ printf "apt\t%s\n", $1 }'
fi
