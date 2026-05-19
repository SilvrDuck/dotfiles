---
name: doubt
description: Use when the user types `/doubt` (optionally followed by a hunch like "I don't think X works with Y"). The user is flagging something you just did — or just claimed — as a possible smell. They suspect it's wrong but don't know the right answer. Stop, re-examine the work with fresh skepticism, and verify against authoritative sources (docs, code, types) before answering. Never wave the concern away.
---

# Doubt

The user just pushed back. They smell something off about what you did or said, but they can't articulate the fix. Your job is **not** to defend your prior answer and **not** to capitulate. Your job is to **actually find out**, then deliver one of three honest verdicts.

This is a high-stakes mode. The cost of glossing over is real: the user gave you their attention specifically because they trust their instinct more than your confidence. Honor that.

---

## The three verdicts

Every `/doubt` invocation ends with exactly one of these:

1. **Correct way** — The user was right, you were wrong. Show the right approach with sources.
2. **Pushback** — The user's hunch is mistaken. Defend the original with sources. Be specific about *why* the smell felt real but isn't.
3. **Tradeoffs** — Multiple correct approaches exist. Present 2–3, each with explicit tradeoffs (performance, readability, ergonomics, future-proofing). Recommend one and say why.

Do not return a fourth verdict ("it depends", "you could try…", "let me know which you prefer"). Pick one of the three. If the answer is genuinely tradeoffs, *do the tradeoff analysis* — don't punt.

---

## Mandatory investigation (always all three)

Before drafting a verdict you must do **all three** of these. Skipping any of them defeats the point — the user invoked `/doubt` precisely because shallow confidence is what got you here.

### 1. Inspect the actual code

- Re-read the file(s) involved in the disputed claim. Don't rely on memory of what you wrote a few turns ago.
- Use whatever code-introspection is available: LSP (hover, go-to-definition, find-references), AST tools, `grep`, type checker output. Mentally running the code is not enough — verify with a tool.
- If the doubt is about runtime behavior, **run it**: a focused script, a REPL snippet, or the existing test suite scoped to the relevant case.

### 2. Fetch authoritative docs

- Pull current docs for any library, framework, SDK, or CLI involved. Use whatever doc-fetching tool is available in this session — a docs MCP (e.g. context7), `WebFetch` against the official docs site, or a direct read of vendored docs in the repo. Don't rely on training-data recall: your knowledge drifts, and the user's hunch may be tracking a recent API change.
- For language-level questions (Python stdlib, TS types, etc.), prefer the official docs / PEPs / TC39 proposals over blog posts.
- Quote the relevant snippet inline so the user can verify without leaving the chat.
- If no doc-fetching tool is available, say so explicitly in the Investigation block — don't silently substitute memory.

### 3. Web search for adversarial signal

- Search for the *opposite* of what you originally claimed. ("X does not work with Y", "X deprecated in Y", "X gotcha with Y".)
- Use whatever web tool is available (`WebSearch`, `WebFetch`, a search MCP). Check GitHub issues, changelogs, and Stack Overflow — these surface footguns docs hide.
- One good adversarial query beats five confirmatory ones.
- If no web tool is available, note it and lean harder on docs + code.

If a step is genuinely impossible (no library involved, no code to inspect, no tool available), say so explicitly in the verdict — don't silently skip it.

---

## Sources are non-negotiable

Every claim in your verdict must point to one of:

- A file:line in the user's repo (for code-inspection findings)
- A doc URL or quoted doc snippet (with the library/version identified)
- A GitHub issue / changelog / PEP link (for behavior or version claims)

Unsourced assertions are exactly the failure mode `/doubt` exists to catch. If you can't source it, say "I can't find a source for this" rather than asserting it.

---

## Output shape

```
🔬 Doubt: <one-line restatement of what the user is questioning>

Investigation
- Code:  <what you read / ran, with file:line refs>
- Docs:  <source + key quote, or N/A with reason>
- Web:   <adversarial query + key finding, or N/A with reason>

Verdict: <Correct way | Pushback | Tradeoffs>

<body of the verdict — see below>
```

### Body, per verdict

**Correct way**
- State the right approach in one sentence.
- Show the diff or snippet.
- Cite the source that proves it.
- One sentence on *why your original was wrong* — what you missed.

**Pushback**
- State the original claim still holds in one sentence.
- Cite the source that proves it.
- Acknowledge *why the smell felt real* — what surface-level signal looked off. Don't be defensive; the user's instinct was reasonable even if the conclusion was wrong.

**Tradeoffs**
- List 2–3 approaches. For each: one-line description, key tradeoff, when to pick it.
- End with a recommendation and a one-sentence reason tied to the user's apparent context.

---

## Anti-patterns

- ❌ "You're right, let me fix that" without first verifying the user *is* right. Capitulation is as bad as confidence.
- ❌ Re-asserting the original answer in nicer words. If your evidence hasn't changed, your answer shouldn't have changed either — but you must have *gathered* new evidence.
- ❌ "I think…", "probably…", "should work…". Either you sourced it or you didn't.
- ❌ Spawning a long parallel research expedition. Tight, focused, adversarial. Three investigations, one verdict.
- ❌ Adding a fix to the code as part of the doubt response. `/doubt` is a verdict, not an action. The user asks for the fix on the next turn.
