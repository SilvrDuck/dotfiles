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
$(chezmoi source-path)/scripts/setup-obsidian-vault
$(chezmoi source-path)/scripts/setup-interactive-logins
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

## Obsidian

```sh
# macOS

# follow sync log
tail -f ~/Library/Logs/vault-sync.log
# run sync now
launchctl kickstart -k gui/$(id -u)/com.silvrduck.vault-sync
# uninstall the launch agent
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.silvrduck.vault-sync.plist

# Linux

# follow sync log
journalctl --user -u vault-sync.service -f
# run sync now
systemctl --user start vault-sync.service
# stop and disable the timer
systemctl --user disable --now vault-sync.timer
```
