Copy-paste snippet for `devcontainer.json`:

```json
"postCreateCommand": "sh -c \"$(curl -fsLS https://get.chezmoi.io)\" -- init --one-shot --apply --promptChoice \"Machine kind=devcontainer\" SilvrDuck"
```