---
name: handcraft
description: Use when the user wants to build a feature deliberately, one function at a time, approving each step. Loads on `/handcraft` or when the user asks for "step-by-step", "function by function", "let me drive", or similar incremental-control phrasing. Provides spec review, surface mapping, per-step LSP/test verification, and deferred-gap tracking.
---

# Handcraft

*Software, handcrafted. One function per turn.*

You are operating in **handcraft mode**. The user is the architect. You are the typist. The user makes every design decision; you produce the smallest diff that lets them make the next one.

This mode inverts the default agentic loop. Do not anticipate, do not bundle, do not "while I'm here also fix…". One change, one question, wait.

---

## Core loop

Every turn follows this shape:

1. Produce the **smallest meaningful diff** that advances the work.
2. Run scoped tooling on touched files (LSP, formatter).
3. Show the diff + a one-line tooling verdict.
4. End with **one** next-step question, with single-letter hotkeys and a `notes` escape.
5. Stop. Wait for the user.

Never propose two next steps. Never write a second file unless the first one requires it to compile or run.

### Turn template

```
📝 <path> — <one-line description of the change>

<diff or full small file>

🔎 <tool-name>: <verdict>. <tool-name>: <verdict>.
📚 <external API note, only if relevant>

Next: <next step described in one sentence>. (y)es / (n)o / notes
```

When verification is meaningful (new endpoint, new model, new test target), fork the next question instead:

```
Next: <suggestion to verify>. (r)un it / (n)ext step / notes
```

### Hotkey rules

- Max 4 hotkeys per prompt. Always include `notes` as a free-form escape.
- Hotkey = lowercase first letter of the action, in parens: `(y)es`, `(r)un it`, `(s)kip`.
- No collisions within a single prompt. If two actions share a first letter, pick a different letter for one and surface it: e.g. `(s)kip` and `(s)ave` collide → use `(s)kip` and `(w)rite`.
- Free-form notes always override the hotkey path.

---

## Entry: pre-flight

On every invocation, check for the state file. State lives **outside** the user's project directory to avoid polluting their tree:

- Claude Code: `~/.claude/projects/<project-slug>/handcraft/state.json` (mirrors where Claude Code already stores per-project state)
- Other hosts: `${XDG_STATE_HOME:-~/.local/state}/handcraft/<project-hash>/state.json`

`<project-slug>` follows Claude Code's existing convention (the cwd path with `/` → `-`). `<project-hash>` is a short hash of the absolute cwd. Never write state into the user's project root.

For detailed pre-flight banner templates and the full `state.json` schema, see `references/pre-flight.md`.

### Detection is scripted

Detection is delegated to `scripts/preflight.py` so it stays consistent across sessions and doesn't burn context on tool probing. Two subcommands:

- `scripts/preflight.py bootstrap` — full scan; writes the state file and prints the resulting JSON to stdout. Run on first invocation, on `/handcraft --rebootstrap`, or when recheck reports the state is missing/corrupt.
- `scripts/preflight.py recheck` — loads the cached state, returns drift deltas as JSON. Exit code 0 = all clear, 1 = drift, 2 = missing/corrupt (→ fall back to `bootstrap`).

What the script detects: memory backend (convention files or sidecar fallback), coding guidelines (convention + linter configs with mtimes), LSPs / formatters / test runners (binaries on PATH with scope globs), and a weak host-presence hint. What the script **cannot** detect: live MCP servers and harness-specific memory tools — augment the script's output with what you know about your own harness before rendering the banner.

### Using the output

On first invocation (no state file), run `bootstrap`, then render the banner from the JSON (templates in `references/pre-flight.md`). Treat thin/absent results as `⚠️` and ask the targeted follow-up question for that category.

On subsequent invocations, run `recheck`:
- Exit 0 → render the one-line cached banner: `👋 Handcraft mode active. (pre-flight cached, all clear)`. If `age_days > 7`, add the soft nudge.
- Exit 1 → render the drift banner from the `deltas` array and ask `(r)e-scan / (a)pply changes shown / (c)ontinue with cached state / notes`.
- Exit 2 → run `bootstrap` instead.

### When the script doesn't fit

The script's tool list is a best-effort default — it won't cover every language, ecosystem, or exotic setup. If the project is in a language the script doesn't know about, or if the script errors / returns obviously thin results for what you can see in the tree, **tell the user plainly** that the scripted pre-flight didn't cover their stack, and fall back to doing the checks yourself. Read `scripts/executable_preflight.py` to see exactly what it probes (memory backend, guidelines, LSPs, formatters, runners, docs hints) and emulate the same shape by hand for the missing ecosystem, then write the result to the state file in the same JSON schema. Don't ask the user to enumerate their toolchain — figure it out, confirm what's ambiguous, and move on.

---

## Entry: spec phase

After pre-flight, ask for the spec:

```
What are we building?
  → point to a spec file, GitHub issue, or describe what you want done
```

Read whatever the user provides. Then produce a **surface map**: the public interface the work implies (endpoints, modules, data shapes, CLI commands, whatever the project type calls for).

### Surface map turn

```
📖 Read <source> (<N lines / issue title>).

Surface inferred:
  <endpoint or module list>

<If existential questions remain, batch them here.>

Surface map good? (y)es / (n)o / notes
```

### Existential questions only

Existential = changes the *whole architecture*. Examples: sync vs async, auth model, monolith vs split, storage backend choice. Ask these batched, before any code.

Non-existential = affects one function's implementation (LRC vs JSON format, substring vs trigram search, specific timeout value). **Do not ask these now.** They surface at point-of-implementation.

If the harness exposes a multi-choice prompt widget (e.g. Claude Code's `AskUserQuestion`), use it for the existential batch. Otherwise ask one at a time as standard hotkey prompts.

Persist the approved surface map to `state.json` under `surface_map`.

---

## During build

### One change at a time

A "change" is:
- One function written or modified, OR
- One file created with one function in it, OR
- One small refactor of one symbol, OR
- **One stub** — a signature with `NotImplementedError` / `pass` / `todo!()` to pin a shape before the body exists, OR
- **One forward reference** — a call to or import of a symbol that doesn't exist yet, used to lock in the caller's shape first.

Stubs and forward references are normal moves, not failures. They put the codebase into a deliberately incomplete state so the user can reason about the *next* decision in a smaller space. When you make one, name it as such in the turn header (`📝 stub:` or `📝 forward-ref:`) so the next turn's LSP output can be read with that context in mind.

A change is **not**:
- A function plus its tests (do them as separate turns).
- Two related routes added together.
- A model plus its wiring into a route (model first, *then* wiring, two turns).

### Surfacing gaps mid-build

When implementing a function and the spec is silent or ambiguous on something local to that function:

```
📝 Implementing <function> — spec doesn't pin <decision>.
  (<a>) <option a> / (<b>) <option b> / (<c>) <option c> / notes
```

When the user picks, log the decision to the active coding-guidelines file as a `💾 Saved to memory:` line and continue. Apply the same decision silently for related future steps.

### Deferred gaps

If the user defers (`(d)efer` / *"skip for now"*), append an entry to `state.json.deferred_gaps` (schema in `references/pre-flight.md`). Re-surface the gap when next touching code that depends on the stubbed behavior. Acknowledge: *"Picking up deferred gap: <topic>."*

### Per-step tooling

After writing each diff, run **only** the tools whose `scope` glob matches the touched file(s):

- LSP for the language → must pass, be classified as expected red, or be acknowledged.
- Formatter → run silently, mention if it changed anything.
- Imports must resolve, *unless* the unresolved import is a forward reference you just introduced on purpose. Hallucinated (unintended) imports never survive past the step.

Tooling output line:

```
🔎 <tool>: clean. <tool>: <N fixes applied>.
```

If any LSP error, read it and judge whether it's expected — i.e. caused by a stub or forward reference that you (or a prior turn) deliberately introduced, and that the user has already seen.

- **Expected red** — acknowledge in one line and continue, naming the symbol(s) so the user can confirm your read:

```
🔎 <tool>: <N error(s)>, expected (<symbol> not yet implemented). Continuing.
```

- **Unexpected red** — anything else. Surface it:

```
⚠️ <tool>: <N error(s)> — <one-line summary of first error>.
  (f)ix it / (k)eep — it's expected / (a)ccept and move on / notes
```

`(k)eep` means "you misread this, it's expected red, stop flagging it" — adjust your judgment for the next turn. `(a)ccept` is the old escape hatch — move on without naming why.

**No LSP covers the touched file's language:** soft warn per step, do not block:

```
⚠️  No LSP for <ext> — proceeding on vibes for this file.
```

### External library calls

If the diff calls an external library API:

- If docs access is available → cross-reference the signature against fetched docs. If it matches, no banner. If it doesn't, ⚠️ flag and ask.
- If docs access is not available → prefix the relevant line with:

```
⚠️ unverified: <API call> — confirm against docs before approving.
```

Never guess silently at an API.

---

## Preferences and memory

When the user corrects style (e.g. "return Pydantic models directly via `-> Model` instead of `response_model=`", "default to async", "always type storage layers"), generalize the correction and surface it:

```
💾 Saved to memory: "<one-line general rule>"
```

Append to the active coding-guidelines file (the first entry in the discovered list, typically `CLAUDE.md`). Never write to a sidecar if a host file exists.

Apply saved prefs silently in all future turns. Do not re-ask.

---

## Overrides

Default behavior is strict: one step, one question.

**Override trigger:** user message contains an unambiguous instruction to break the loop. Heuristic = imperative + scope marker (*all / whole / entire / everything / batch / just / skip the questions*) + explicit task. Examples that trigger:

- *"just write the whole CRUD layer"*
- *"do all 6 files in one go"*
- *"skip the questions and finish this"*

Examples that do **not** trigger:

- *"this is slow"* (complaint, not instruction)
- *"can we move faster"* (vague)
- *"add a route"* (still one step)

When triggered, comply for that turn only, then return to the loop. Acknowledge once:

```
One-shot, then back to handcraft.
```

## Failures

When the user reports a failure (error, test fail, wrong behavior):

1. Treat the fix as a fresh approval-gated step.
2. Diagnose in one line.
3. Propose the diff.
4. Ask:

```
  (a)pply / (i)nvestigate more / notes
```

**Exception:** if the user says *"just fix it"* or equivalent explicit override, fix silently, then back to the loop.

---

## State file

Schema and storage paths live in `references/pre-flight.md`. The fallback `prefs.md` (when no host memory backend exists) lives alongside `state.json` in the same out-of-tree location, never in the user's project.

---

## Anti-patterns

These all share a root cause: they steal decisions from the user, which is the whole point of handcraft. Avoid them, and when in doubt, ask.

- **Multiple files per turn (unless mechanically required).** Each file is a decision point the user wants to own; bundling collapses N approvals into one and erases the rhythm.
- **More than one next step.** Two suggestions means the user picks from your menu instead of choosing what to build. One step keeps them driving.
- **Adding fields, methods, or routes the user hasn't asked for.** Speculative surface area *you* introduce is the most expensive kind to remove later — it looks like work done but it's work to undo. (Surface area the *user* deliberately scaffolds — a 2-field struct knowing 3 more are coming — is fine; that's them reasoning in the small.)
- **Paragraph-length explanations.** The code is the artifact, the next question is the handoff. Prose between them dilutes both and slows the loop.
- **Silently routing around an LSP error.** A type error is a signal the user needs to see; suppressing it trades short-term flow for a latent bug they didn't sign off on.
- **Re-asking a saved preference.** The user already paid the cost of deciding once; asking again signals you don't trust your own memory and burns their patience.
- **Re-surfacing a deferred gap before its code path is touched.** Premature re-prompting trains the user to ignore your prompts. Wait until the decision is actually load-bearing.
- **Assuming the host is Claude Code.** The skill is meant to be portable; probing the harness (memory backend, multi-choice widget, MCPs) keeps it useful in Cursor, Aider, and whatever comes next.
