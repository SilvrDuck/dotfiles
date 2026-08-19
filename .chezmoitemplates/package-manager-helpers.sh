# Install wrappers: one per package manager, plus the root-free fallbacks for
# machines where none of them is reachable. Each is best-effort: failures
# echo "skipped or failed" and return 0 so the surrounding loop continues.

install_brew() {
  local kind="$1"
  local name="$2"
  local leaf="${name##*/}"

  # Presence only -- the weekly upgrade step owns upgrades. Skip anything brew
  # already tracks (BREW_INSTALLED_* are snapshotted once by the caller) so a
  # re-apply stays quiet and never triggers an interactive upgrade prompt for an
  # outdated-but-installed formula.
  if [ "$kind" = "cask" ]; then
    printf '%s\n' "${BREW_INSTALLED_CASKS:-}" | grep -qxF "$leaf" && return 0
  else
    printf '%s\n' "${BREW_INSTALLED_FORMULAE:-}" | grep -qxF "$leaf" && return 0
  fi

  # Third-party tap packages (user/tap/name) are trusted as part of install.
  # Untrusted taps only warn today, but Homebrew 6.0 will ignore them
  # outright -- silently breaking these installs.
  case "$name" in
    */*)
      if [ "$kind" = "cask" ]; then
        brew trust --cask "$name" || echo "[brew trust] skipped or failed: $name"
      else
        brew trust --formula "$name" || echo "[brew trust] skipped or failed: $name"
      fi
      ;;
  esac

  if [ "$kind" = "cask" ]; then
    echo "[brew cask] $name"
    # --adopt claims a pre-existing app (installed by hand) instead of erroring.
    brew install --cask --adopt "$name" || echo "[brew cask] skipped or failed: $name"
  else
    echo "[brew] $name"
    brew install "$name" || echo "[brew] skipped or failed: $name"
  fi
}

install_pacman() {
  local name="$1"
  echo "[pacman] $name"
  $SUDO pacman -S --needed --noconfirm "$name" || echo "[pacman] skipped or failed: $name"
}

install_yay() {
  local name="$1"

  if ! command -v yay >/dev/null 2>&1; then
    cat >&2 <<'YAY'
[packages] AUR package wanted, but yay is not installed.
Install yay manually if you want AUR packages, then rerun: chezmoi apply

Typical Arch steps:
  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si
YAY
    return 0
  fi

  echo "[yay] $name"
  yay -S --needed --noconfirm "$name" || echo "[yay] skipped or failed: $name"
}

install_apt() {
  local name="$1"
  echo "[apt] $name"
  $SUDO apt-get install -y "$name" || echo "[apt] skipped or failed: $name"
}

# mise stands in for the system package manager where root is out of reach: its
# aqua/ubi backends unpack prebuilt binaries under ~/.local, and dot_zshrc's
# `mise activate` puts them on PATH. Tools land in their own conf.d fragment so
# ~/.config/mise/config.toml stays whatever the machine's owner made it.
MISE_DOTFILES_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/mise/conf.d/dotfiles.toml"

install_mise() {
  local spec="$1"
  echo "[mise] $spec"
  mkdir -p "${MISE_DOTFILES_CONF%/*}"
  mise use --yes --path "$MISE_DOTFILES_CONF" "$spec" \
    || echo "[mise] skipped or failed: $spec"
}

# Homebrew when the machine already has it -- it needs no root once installed
# -- and mise for everything else. An empty argument means that route does not
# exist for the package; both empty leaves it to whoever does have admin.
install_nosudo() {
  local tool="$1" kind="$2" pkg="$3" spec="$4"
  if [ -n "$pkg" ] && command -v brew >/dev/null 2>&1; then
    install_brew "$kind" "$pkg"
  elif [ -n "$spec" ] && command -v mise >/dev/null 2>&1; then
    install_mise "$spec"
  else
    echo "[nosudo] no root-free source for $tool"
  fi
}

# Unpack-into-$HOME installers, shared by the apt branch (whose repos stale or
# miss these) and by machines with no usable repos at all.

install_manual_antidote() {
  if [ -r "$HOME/.local/share/antidote/antidote.zsh" ]; then return 0; fi
  echo "[manual] antidote"
  rm -rf "$HOME/.local/share/antidote"
  git clone --depth 1 https://github.com/mattmc3/antidote.git "$HOME/.local/share/antidote" || true
}

install_manual_jetbrains_mono_nerd() {
  local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
  if [ "$(uname -s)" = "Darwin" ]; then
    font_dir="$HOME/Library/Fonts/JetBrainsMono"
  fi
  if [ -d "$font_dir" ] || fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
    return 0
  fi
  echo "[manual] JetBrains Mono Nerd Font"
  # fontconfig (fc-cache) is in Ubuntu base; install it just in case.
  if command -v apt-get >/dev/null 2>&1 && ! command -v fc-cache >/dev/null 2>&1; then
    $SUDO apt-get install -y fontconfig >/dev/null 2>&1 || true
  fi
  local tmp
  tmp=$(mktemp -d)
  if curl -fsSL -o "$tmp/font.tar.xz" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"; then
    mkdir -p "$font_dir"
    tar -C "$font_dir" -xJf "$tmp/font.tar.xz" \
      || echo "[manual] JetBrains Mono Nerd Font: install failed"
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$font_dir" >/dev/null
    fi
  else
    echo "[manual] JetBrains Mono Nerd Font: download failed"
  fi
  rm -rf "$tmp"
}

# Per-machine opt-in gate. scripts/pick-packages records one "<id>=1" (install)
# or "<id>=0" (skip) line per optional package in this file; pkg_chosen is true
# only for "=1". A missing file means nothing optional installs, so a fresh or
# non-interactive machine gets the baseline only until the picker runs.
CHOICES_FILE="${CHOICES_FILE:-$HOME/.config/dotfiles/package-choices}"

pkg_chosen() {
  grep -qxF "$1=1" "$CHOICES_FILE" 2>/dev/null
}
