# Manual installers for tools missing or stale in default Ubuntu/Debian apt repos.
# Included via {{`{{ template "apt-manual-installers.sh" . }}`}} from
# run_onchange_after_10-packages.sh.tmpl. Each install_manual_* is idempotent
# (guards on `command -v` or a sentinel file) and safe to re-run.

gh_latest_version() {
  # echoes the latest release tag without leading "v" (e.g. "0.61.1")
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v?([^"]+)".*/\1/p' \
    | head -n1
}

install_github_tar() {
  # install_github_tar <bin> <url> [tar_extract_flags]
  # tar_extract_flags defaults to "-xzf"; pass "--zstd -xf" for .tar.zst.
  local bin="$1" url="$2"
  local flags="${3:--xzf}"
  local tmp found
  tmp=$(mktemp -d)
  if curl -fsSL -o "$tmp/archive" "$url" \
    && tar -C "$tmp" $flags "$tmp/archive"; then
    found=$(find "$tmp" -type f -name "$bin" 2>/dev/null | head -n1)
    if [ -n "$found" ]; then
      $SUDO install -m 0755 "$found" "/usr/local/bin/$bin" \
        || echo "[manual] $bin: install failed"
    else
      echo "[manual] $bin: binary '$bin' not found in archive"
    fi
  else
    echo "[manual] $bin: download or extract failed"
  fi
  rm -rf "$tmp"
}

install_manual_antidote() {
  if [ -r "$HOME/.local/share/antidote/antidote.zsh" ]; then return 0; fi
  echo "[manual] antidote"
  rm -rf "$HOME/.local/share/antidote"
  git clone --depth 1 https://github.com/mattmc3/antidote.git "$HOME/.local/share/antidote" || true
}

install_manual_neovim() {
  # Debian/Ubuntu apt nvim is years behind (often 0.7.x); LazyVim needs >=0.8.
  # Drop the official Linux tarball into /opt and symlink onto /usr/local/bin.
  echo "[manual] neovim (tarball)"
  local arch asset tmp
  arch=$(uname -m)
  case "$arch" in
    x86_64)  asset=nvim-linux-x86_64 ;;
    aarch64) asset=nvim-linux-arm64 ;;
    *) echo "[manual] neovim: unsupported arch $arch, skipping"; return 0 ;;
  esac
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/nvim.tar.gz" "https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz" \
    && $SUDO rm -rf "/opt/${asset}" \
    && $SUDO tar -C /opt -xzf "$tmp/nvim.tar.gz" \
    && $SUDO ln -sf "/opt/${asset}/bin/nvim" /usr/local/bin/nvim \
    || echo "[manual] neovim: install failed"
  rm -rf "$tmp"
}

install_manual_starship() {
  if command -v starship >/dev/null 2>&1; then return 0; fi
  echo "[manual] starship"
  curl -fsSL https://starship.rs/install.sh | $SUDO sh -s -- -y \
    || echo "[manual] starship: install failed"
}

install_manual_mise() {
  if command -v mise >/dev/null 2>&1; then return 0; fi
  echo "[manual] mise"
  # installs to ~/.local/bin/mise; already on PATH via zshrc.
  curl -fsSL https://mise.run | sh \
    || echo "[manual] mise: install failed"
}

install_manual_eza() {
  if command -v eza >/dev/null 2>&1; then return 0; fi
  echo "[manual] eza"
  local asset
  case "$(uname -m)" in
    x86_64)  asset=eza_x86_64-unknown-linux-gnu.tar.gz ;;
    aarch64) asset=eza_aarch64-unknown-linux-gnu.tar.gz ;;
    *) echo "[manual] eza: unsupported arch $(uname -m)"; return 0 ;;
  esac
  install_github_tar eza \
    "https://github.com/eza-community/eza/releases/latest/download/${asset}"
}

install_manual_carapace() {
  if command -v carapace >/dev/null 2>&1; then return 0; fi
  echo "[manual] carapace"
  local arch ver
  case "$(uname -m)" in
    x86_64)  arch=amd64 ;;
    aarch64) arch=arm64 ;;
    *) echo "[manual] carapace: unsupported arch $(uname -m)"; return 0 ;;
  esac
  ver=$(gh_latest_version carapace-sh/carapace-bin)
  if [ -z "$ver" ]; then
    echo "[manual] carapace: could not resolve latest version"
    return 0
  fi
  install_github_tar carapace \
    "https://github.com/carapace-sh/carapace-bin/releases/download/v${ver}/carapace-bin_${ver}_linux_${arch}.tar.gz"
}

install_manual_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then return 0; fi
  echo "[manual] lazygit"
  local arch ver
  case "$(uname -m)" in
    x86_64)  arch=Linux_x86_64 ;;
    aarch64) arch=Linux_arm64 ;;
    *) echo "[manual] lazygit: unsupported arch $(uname -m)"; return 0 ;;
  esac
  ver=$(gh_latest_version jesseduffield/lazygit)
  if [ -z "$ver" ]; then
    echo "[manual] lazygit: could not resolve latest version"
    return 0
  fi
  install_github_tar lazygit \
    "https://github.com/jesseduffield/lazygit/releases/download/v${ver}/lazygit_${ver}_${arch}.tar.gz"
}

install_manual_jetbrains_mono_nerd() {
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then return 0; fi
  echo "[manual] JetBrains Mono Nerd Font"
  # fontconfig (fc-cache) is in Ubuntu base; install it just in case.
  command -v fc-cache >/dev/null 2>&1 || $SUDO apt-get install -y fontconfig >/dev/null 2>&1 || true
  local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
  local tmp
  tmp=$(mktemp -d)
  if curl -fsSL -o "$tmp/font.tar.xz" \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"; then
    mkdir -p "$font_dir"
    tar -C "$font_dir" -xJf "$tmp/font.tar.xz" \
      && fc-cache -f "$font_dir" >/dev/null \
      || echo "[manual] JetBrains Mono Nerd Font: install failed"
  else
    echo "[manual] JetBrains Mono Nerd Font: download failed"
  fi
  rm -rf "$tmp"
}

install_manual_xh() {
  if command -v xh >/dev/null 2>&1; then return 0; fi
  echo "[manual] xh"
  local triple ver
  case "$(uname -m)" in
    x86_64)  triple=x86_64-unknown-linux-musl ;;
    aarch64) triple=aarch64-unknown-linux-musl ;;
    *) echo "[manual] xh: unsupported arch $(uname -m)"; return 0 ;;
  esac
  ver=$(gh_latest_version ducaale/xh)
  if [ -z "$ver" ]; then
    echo "[manual] xh: could not resolve latest version"
    return 0
  fi
  install_github_tar xh \
    "https://github.com/ducaale/xh/releases/download/v${ver}/xh-v${ver}-${triple}.tar.gz"
}

install_manual_d2() {
  if command -v d2 >/dev/null 2>&1; then return 0; fi
  echo "[manual] d2"
  curl -fsSL https://d2lang.com/install.sh | $SUDO sh -s -- \
    || echo "[manual] d2: install failed"
}

install_manual_pay_respects() {
  if command -v pay-respects >/dev/null 2>&1; then return 0; fi
  echo "[manual] pay-respects"
  local triple ver
  case "$(uname -m)" in
    x86_64)  triple=x86_64-unknown-linux-musl ;;
    aarch64) triple=aarch64-unknown-linux-musl ;;
    *) echo "[manual] pay-respects: unsupported arch $(uname -m)"; return 0 ;;
  esac
  # tar --zstd needs zstd on PATH; it's in apt by default on Ubuntu.
  command -v zstd >/dev/null 2>&1 || $SUDO apt-get install -y zstd >/dev/null 2>&1 || true
  ver=$(gh_latest_version iffse/pay-respects)
  if [ -z "$ver" ]; then
    echo "[manual] pay-respects: could not resolve latest version"
    return 0
  fi
  install_github_tar pay-respects \
    "https://github.com/iffse/pay-respects/releases/download/v${ver}/pay-respects-${ver}-${triple}.tar.zst" \
    "--zstd -xf"
}
