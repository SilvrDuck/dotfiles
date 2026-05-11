# Install the AI agents this setup expects, best-effort from upstream installers.
# Intentional curl|bash: Claude Code, OpenCode, and Pi are core to this setup.
# Review those URLs if that ever feels wrong.

cat <<'AIINSTALL'
[packages] Installing AI agents from upstream install scripts, best-effort.
This is intentional: Claude Code, OpenCode, and Pi are core to this setup.
Review these URLs if that ever feels wrong.
AIINSTALL

install_pi() {
  if command -v pi >/dev/null 2>&1; then return 0; fi

  echo "[npm] @earendil-works/pi-coding-agent"

  if command -v mise >/dev/null 2>&1; then
    mise x node@lts -- npm install -g @earendil-works/pi-coding-agent || true
  elif command -v npm >/dev/null 2>&1; then
    npm install -g @earendil-works/pi-coding-agent || true
  else
    echo "[pi] skipped: npm or mise is required"
  fi
}

command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash || true
command -v opencode >/dev/null 2>&1 || curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path || true
install_pi
