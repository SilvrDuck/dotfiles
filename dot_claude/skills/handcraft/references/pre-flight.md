# Handcraft — pre-flight reference

Read this when running the first-time bootstrap, handling drift on subsequent invocations, or persisting state. The main SKILL.md keeps the loop tight; details live here.

## State file location

State must never live in the user's project root. Choose by host:

- **Claude Code:** `~/.claude/projects/<project-slug>/handcraft/state.json` — mirrors the existing per-project state convention. `<project-slug>` is the absolute cwd with `/` replaced by `-` (e.g. `/Users/me/code/foo` → `-Users-me-code-foo`).
- **Other hosts:** `${XDG_STATE_HOME:-~/.local/state}/handcraft/<project-hash>/state.json`. `<project-hash>` is a short hash (first 12 hex chars of SHA-256 is fine) of the absolute cwd.

The fallback `prefs.md` (only created when no host memory backend exists) sits alongside `state.json` in the same directory.

## Pre-flight banner (first-time or rebootstrap)

```
👋 Handcraft mode active.

Pre-flight checks:
  ✅ Memory backend       → <kind/path>
  ✅ Coding guidelines    → <comma-separated sources>
  ✅ LSPs                 → <kind (scope-language)>, ...
  ⚠️  Docs access         → <kind>, ... (or "none detected")
  ✅ Test runners         → <kind (scope)>, ...
  ✅ Formatters           → <kind (scope)>, ...
```

If any check is `⚠️` or `❌`, ask one targeted question to resolve before continuing.

**Coding guidelines absent or thin:**
```
⚠️ No coding guidelines found. Handcraft works best when style preferences are explicit — they get applied silently across every step.
  (d)raft a starter guidelines file with me / (i)nfer from existing code / (c)ontinue without / notes
```

**Docs access absent:**
```
⚠️ No docs access. I'll flag every external-library call as unverified until you confirm.
  (i)nstall context7 MCP / (f)etch via web when needed / (c)ontinue, I'll paste docs / notes
```

## Drift banner (subsequent invocations)

If anything changed since the cached run, surface only the deltas:

```
👋 Handcraft mode active.

Since last session:
  ⚠️  <path> modified — re-scan?
  ❌ <tool> no longer on PATH
  ➕ <new tool> now available — register?

  (r)e-scan everything / (a)pply changes shown / (c)ontinue with cached state / notes
```

If `bootstrapped_at` is older than 7 days, show a soft nudge but do not block:

```
⚠️  Pre-flight state is N days old. Light re-check shows all clear, but run /handcraft --rebootstrap if tooling changed.
```

## state.json schema

```json
{
  "version": 1,
  "bootstrapped_at": "ISO-8601 timestamp",
  "memory_backend": { "kind": "string", "path": "string" },
  "coding_guidelines": [
    { "kind": "convention|linter_config", "path": "string", "rule_count": 0, "mtime": "ISO-8601" }
  ],
  "lsps": [
    { "kind": "string", "version": "string", "scope": "glob", "ok": true }
  ],
  "docs_access": [
    { "kind": "mcp|web_fetch|offline", "name": "string", "ok": true }
  ],
  "test_runners": [
    { "kind": "string", "scope": "glob", "ok": true }
  ],
  "formatters": [
    { "kind": "string", "scope": "glob", "ok": true }
  ],
  "surface_map": { "<project-shape, free-form>": "..." },
  "deferred_gaps": [
    { "topic": "string", "stubbed": "string", "raised_at_step": 0 }
  ]
}
```
