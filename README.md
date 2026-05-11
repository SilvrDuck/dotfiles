# Quickstart

Personal chezmoi dotfiles for macOS, Linux, Omarchy, and devcontainers.

Tries to not override Omarchy stuff.

## Desktop

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply SilvrDuck
```

## Scripts

```bash
$(chezmoi source-path)/scripts/setup-git-default-context
$(chezmoi source-path)/scripts/setup-git-additional-context
$(chezmoi source-path)/scripts/setup-api-keys
$(chezmoi source-path)/scripts/setup-keyboard-layout
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
  "postCreateCommand": "chezmoi update --apply || true"
```

## Obsidian

```sh
# macOS
tail -f ~/Library/Logs/vault-sync.log
launchctl kickstart -k gui/$(id -u)/com.silvrduck.vault-sync
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.silvrduck.vault-sync.plist

# Linux
journalctl --user -u vault-sync.service -f
systemctl --user start vault-sync.service
systemctl --user disable --now vault-sync.timer
```

