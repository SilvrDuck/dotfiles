# Quickstart

Personal chezmoi dotfiles for macOS, Linux, Omarchy, and devcontainers.

Tries to not override Omarchy stuff.

## Desktop

On a fresh Mac, run first and wait for it to finish:

```sh
xcode-select --install
```

Then:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply SilvrDuck
```

## Scripts

Things that genuinely need human input (SSH keys, secrets, browser OAuth,
GUI follow-ups). Anything that can be unattended lives in the chezmoi
bootstrap chain, not here.

```bash
$(chezmoi source-path)/scripts/setup-git-default-context
$(chezmoi source-path)/scripts/setup-git-additional-context
$(chezmoi source-path)/scripts/setup-api-keys
$(chezmoi source-path)/scripts/setup-keyboard-layout
$(chezmoi source-path)/scripts/setup-cli-logins
$(chezmoi source-path)/scripts/setup-gitleaks-local
```

## Devcontainers

Quickest, runs every container start:

```json
"postCreateCommand": "MACHINE_KIND=devcontainer sh -c \"$(curl -fsLS https://get.chezmoi.io)\" -- init --one-shot --apply SilvrDuck"
```

### Faster rebuilds: bake the bootstrap into the image

`.devcontainer/Dockerfile`:

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:bookworm
# FROM mcr.microsoft.com/devcontainers/python:3.12-bookworm
# FROM mcr.microsoft.com/devcontainers/typescript-node:22-bookworm
# FROM mcr.microsoft.com/devcontainers/universal:linux

# Ensure a `vscode` user + passwordless sudo exist. No-op on MS devcontainer
RUN if ! id -u vscode >/dev/null 2>&1; then \
      apt-get update && apt-get install -y --no-install-recommends sudo && \
      useradd -m -s /bin/bash vscode && \
      echo 'vscode ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vscode && \
      chmod 0440 /etc/sudoers.d/vscode; \
    fi

USER vscode
RUN MACHINE_KIND=devcontainer sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply SilvrDuck
```

`.devcontainer/devcontainer.json`:

```jsonc
  "build": { "dockerfile": "Dockerfile" },
  "remoteUser": "vscode",
  "postCreateCommand": "chezmoi update --apply || true",
```

## Claude

```sh
# open this repo in Claude Code from anywhere
clank
```

Then:

```sh
# reconcile local machine state into the repo, per-item review
/consolidate

# enumerate what the best-effort install skipped on this machine
/diagnostic
```

## Raycast

macOS only. The `fleet` Raycast script command ships in `~/.local/share/raycast-scripts/`.

1. Raycast → Settings → Extensions → Scripts → Script Commands → *Add Directories* → `~/.local/share/raycast-scripts`
2. Bind the *Fleet* command to ⌃⌥⌘ Space
3. Set the launcher hotkey to ⌘ Space (accept Raycast's offer to free it from Spotlight)

## Tiling (AeroSpace + AltTab)

macOS only. AeroSpace tiles windows with ⌘ as the "Super" key; AltTab switches windows.

1. Launch AeroSpace → grant **Accessibility** (System Settings → Privacy & Security). It starts at login automatically.
2. Launch AltTab → grant **Accessibility** + **Screen Recording**. Default trigger is ⌥ Tab (Omarchy's Alt+Tab).
3. Keymap lives in `~/.config/aerospace/aerospace.toml`; app launchers are ⌘⇧ + letter, and ⌘⇧; enters service mode (Esc reloads the config).

