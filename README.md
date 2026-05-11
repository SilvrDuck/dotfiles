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
"postCreateCommand": "sh -c \"$(curl -fsLS https://get.chezmoi.io)\" -- init --one-shot --apply --promptChoice \"Machine kind=devcontainer\" SilvrDuck"
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
RUN sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply --promptChoice "Machine kind=devcontainer" SilvrDuck
```

`.devcontainer/devcontainer.json`:

```jsonc
  "build": { "dockerfile": "Dockerfile" },
  "remoteUser": "vscode",
  "postCreateCommand": "chezmoi update --apply || true"
```

