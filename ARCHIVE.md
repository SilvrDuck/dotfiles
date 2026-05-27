# Archive

Sparse index of features the user has explicitly asked to archive. Each entry names the last commit where the feature was live, plus optionally a git tag for the same commit. To inspect: `git show <hash>`. To restore: `git checkout <hash> -- <paths…>` then `chezmoi apply`. **Do not add entries on your own** — only when the user explicitly says "archive this". When you do add one, also tag the prior commit `archive/<short-slug>`. Keep entries terse — commit ref only.

## vault-sync git flow — 2026-05-28
- last-live: `95e55a0`
- tag: `archive/vault-sync-flow`
