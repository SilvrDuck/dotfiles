# Install tools straight from upstream installers, best-effort.
# Intentional curl|bash: these either have no working package, broken taps,
# or move fast enough that vendor scripts are the most honest source.
# Review the URLs below if that ever feels wrong.

cat <<'UPSTREAM'
[packages] Installing upstream tools (uv, chosen AI CLIs, pay-respects on macOS).
This is intentional: review the install URLs in upstream-installers.sh.
UPSTREAM

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

# AI CLIs are opt-in: gated on the per-machine choices file (scripts/pick-packages).
if pkg_chosen "claude-cli"; then
  command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash || true
fi
if pkg_chosen "opencode"; then
  command -v opencode >/dev/null 2>&1 || curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path || true
fi
if pkg_chosen "pi"; then
  install_pi
fi
if pkg_chosen "codex"; then
  command -v codex >/dev/null 2>&1 || curl -fsSL https://chatgpt.com/codex/install.sh | sh || true
fi

# uv: official installer. Graphify needs it; generally useful for Python work.
command -v uv >/dev/null 2>&1 || curl -fsSL https://astral.sh/uv/install.sh | sh || true

{{ if eq .chezmoi.os "darwin" -}}
# pay-respects on macOS: no working brew formula; use the upstream installer.
command -v pay-respects >/dev/null 2>&1 || curl -fsSL https://raw.githubusercontent.com/iffse/pay-respects/main/install.sh | sh || true
{{ end -}}
