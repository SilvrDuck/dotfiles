# Quickstart

Personal chezmoi dotfiles for macOS, Linux, Omarchy, and devcontainers.

Tries to not override Omarchy stuff.

## Desktop

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply SilvrDuck
```

## Devcontainers

```json
"postCreateCommand": "sh -c \"$(curl -fsLS https://get.chezmoi.io)\" -- init --one-shot --apply --promptChoice \"Machine kind=devcontainer\" SilvrDuck"
```

## Scripts

```bash
$(chezmoi source-path)/scripts/setup-git-default-context
$(chezmoi source-path)/scripts/setup-git-additional-context
$(chezmoi source-path)/scripts/setup-api-keys
$(chezmoi source-path)/scripts/setup-keyboard-layout
```