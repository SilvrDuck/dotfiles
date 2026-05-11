# Per-package-manager install wrappers. Each is best-effort: failures
# echo "skipped or failed" and return 0 so the surrounding loop continues.

install_brew() {
  local kind="$1"
  local name="$2"

  if [ "$kind" = "cask" ]; then
    echo "[brew cask] $name"
    brew install --cask "$name" || echo "[brew cask] skipped or failed: $name"
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
