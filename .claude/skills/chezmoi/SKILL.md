---
name: chezmoi-docs
description: Use whenever working with chezmoi (dotfile manager). Triggers on any chezmoi-related task: writing or debugging templates, configuring `.chezmoiignore` / `.chezmoiexternal` / `.chezmoidata`, run_once/run_onchange scripts, source state attribute prefixes (`dot_`, `private_`, `executable_`, etc), password manager integrations, init templates, encryption setup, or any `chezmoi <command>` question. Also triggers on file/path patterns like `~/.local/share/chezmoi/`, `.chezmoi.toml.tmpl`, or any filename starting with `chezmoi`. Fetches authoritative docs from the official repo so answers track the current version rather than relying on potentially stale training data.
---

# chezmoi docs lookup

Use the primer below for basic daily-ops questions. For anything beyond it, fetch the relevant doc page from source. Do not rely on memory: chezmoi adds template functions and command flags often.

## Primer

Source state lives in `~/.local/share/chezmoi/` (a git repo). `chezmoi apply` reconciles target paths (under `~`) to source state. Per-machine config at `~/.config/chezmoi/chezmoi.toml`.

### Source filename attributes

Prefixes encode target attributes. Stackable left-to-right.

- `dot_foo` → `~/.foo`
- `private_` → mode 600/700
- `readonly_` → readonly
- `executable_` → +x
- `empty_` → keep empty
- `encrypted_` → encrypted at rest (age/gpg)
- `symlink_` → file contents are the symlink target
- `create_` → only create if missing (never overwrite)
- `modify_` → script that rewrites existing target in place
- `remove_` → ensure target is absent
- `run_` → script, not a managed file
- `run_once_` / `run_onchange_` → execution policy for scripts
- `.tmpl` suffix → render as Go template
- `literal_` → escape a prefix that would otherwise be interpreted

Combine: `private_dot_ssh/private_encrypted_id_ed25519.tmpl`.

### Core commands

| command | use |
|---|---|
| `init [REPO]` | clone dotfiles repo into source state, optionally `--apply` |
| `add <path>` | bring a target file under management |
| `re-add` | update source from current target contents |
| `edit <path>` | edit source via target path; `--apply` to apply immediately |
| `diff` | preview pending changes |
| `status` | porcelain view of pending changes |
| `apply` | reconcile target to source; `-n -v` for dry run |
| `update` | git pull then apply |
| `merge <path>` | 3-way merge target / source / desired |
| `cd` | shell in source dir |
| `forget <path>` | stop managing without modifying target |
| `managed` / `unmanaged` | list paths under home |
| `doctor` | diagnose setup |
| `execute-template` | test a template against current data |

### Templates

`.tmpl` files render via Go `text/template`. Key data:

- `.chezmoi.os`, `.arch`, `.hostname`, `.username`, `.homeDir`, `.kernel`, `.osRelease.id`
- Static data from `.chezmoidata.<toml|yaml|json>` or `[data]` block in config
- Init-time prompts via `promptString`, `promptBool`, `promptChoice` (and `*Once` variants persist into config)

### Special source files / dirs

- `.chezmoiignore` — gitignore-style patterns (templated). Skip from source state.
- `.chezmoiremove` — newline-delimited list of `~`-relative target paths to delete on every apply (always templated, even without `.tmpl`). **Removing a file from source state only un-manages it; the target persists on every machine. Use this file when you actually want target deletion.**
- `.chezmoidata.<fmt>` — static data merged into template context.
- `.chezmoiexternal.<fmt>` — fetch archives, files, or git repos as managed content.
- `.chezmoiscripts/` — scripts directory (alternative location for `run_*` scripts).
- `.chezmoitemplates/` — reusable snippets, included via `{{ template "name" . }}`.
- `.chezmoi.<fmt>.tmpl` — bootstrap template for the per-machine config file.
- `.chezmoiroot` — points to a subdir if source is nested.

## Fetch pattern

Raw markdown from GitHub (cleaner than the rendered site):

```
https://raw.githubusercontent.com/twpayne/chezmoi/master/assets/chezmoi.io/docs/<path>.md
```

Use WebFetch. Fetch multiple pages in parallel when a question spans concepts and commands.

## Index

### user-guide/
- `setup.md`, `daily-operations.md`, `command-overview.md`
- `templating.md`, `manage-machine-to-machine-differences.md`, `manage-different-types-of-file.md`
- `use-scripts-to-perform-actions.md`, `include-files-from-elsewhere.md`
- `encryption/{age,gpg,rage,transparent,index}.md`
- `machines/{linux,macos,windows,containers-and-vms,general}.md`
- `password-managers/{1password,aws-secrets-manager,azure-key-vault,bitwarden,custom,dashlane,doppler,ejson,gopass,index,keepassxc,keeper,keychain-and-windows-credentials-manager,lastpass,pass,passhole,proton-pass,vault}.md`
- `tools/{editor,diff,merge,http-or-socks5-proxy}.md`
- `advanced/{customize-your-source-directory,install-packages-declaratively,install-your-password-manager-on-init,migrate-away-from-chezmoi,use-chezmoi-with-watchman}.md`
- `frequently-asked-questions/{general,usage,design,encryption,troubleshooting}.md`

### reference/
- `index.md`, `concepts.md`, `application-order.md`, `source-state-attributes.md`, `target-types.md`, `plugins.md`
- `commands/<name>.md` — one per command: add, apply, archive, cat, cd, chattr, completion, data, decrypt, destroy, diff, doctor, dump, edit, edit-config, edit-config-template, edit-encrypted, encrypt, execute-template, forget, generate, git, help, ignored, import, init, license, list, manage, managed, merge, merge-all, purge, readd, remove, rm, secret, source-path, ssh, state, status, target-path, unmanage, unmanaged, update, upgrade, verify
- `command-line-flags/{global,common,developer,index}.md`
- `configuration-file/{index,editor,hooks,interpreters,pinentry,textconv,umask,warnings}.md`
- `special-directories/{chezmoidata,chezmoiexternals,chezmoiscripts,chezmoitemplates,index}.md`
- `special-files/{chezmoiignore,chezmoiremove,chezmoiroot,chezmoiversion,chezmoidata-format,chezmoiexternal-format,chezmoi-format-tmpl,index}.md`
- `templates/{index,directives,variables}.md`
- `templates/functions/<name>.md` — generic funcs: include, includeTemplate, glob, fromJson, fromYaml, fromToml, fromIni, toJson, toYaml, toToml, toIni, exec, output, outputList, lookPath, findExecutable, findOneExecutable, isExecutable, joinPath, jq, stat, lstat, ioreg, mozillaInstallHash, hexEncode, replaceAllRegex, ensureLinePrefix, encrypt, decrypt, deleteValueAtPath, setValueAtPath, getRedirectedURL, pruneEmptyDicts, stdinIsATTY, toPrettyJson, toString, warnf, abortEmpty, completion
- `templates/init-functions/<name>.md` — promptString, promptStringOnce, promptBool, promptBoolOnce, promptChoice, promptChoiceOnce, promptInt, promptIntOnce, promptMultichoice, promptMultichoiceOnce, writeToStdout, exit
- `templates/<provider>-functions/<name>.md` — provider-specific funcs for 1password, aws-secrets-manager, azure-key-vault, bitwarden, dashlane, doppler, ejson, github, gopass, keepassxc, keeper, keyring, lastpass, pass, passhole, protonpass, secret, vault

## Workflow

1. If the question is covered by the primer, answer directly.
2. Otherwise map to the most specific page in the index.
3. WebFetch in parallel if the answer needs concept + command, or template func + example.
4. Cite the page path so the user can deep-link to chezmoi.io.
5. When unsure which page is canonical, start with `reference/index.md` or `user-guide/command-overview.md`.

## Skip the fetch when

- The question is "what is chezmoi" or similar one-liner.
- The primer fully covers it (basic file naming, core command behavior, common templates).
- The user is asking about their own dotfiles structure, not chezmoi semantics. Read their files directly.
