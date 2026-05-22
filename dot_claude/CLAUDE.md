# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# host notes (machine-local memory)
`~/.claude/host-notes.md` is this machine's local memory — **not** synced via chezmoi, **not** committed to any repo, **not** shared. When the user says "host notes" they mean this file. Read it at session start if it exists, and append host-specific facts (paths, tool versions, machine-only context) when asked. Never copy its contents into a repo, a commit, a PR, or any shared channel.

# Questions are not commands
When the user asks "why did you X?", "is this right?", "are you sure?" — answer the question. Do not revert, rewrite, or "fix" anything until the user decides. Skip "you're absolutely right" reflexes — disagree when there is reason, say "I don't know" when uncertain.

# No AI attribution trailers
Never add `Co-Authored-By: Claude …` (or any other AI attribution trailer / signature / marker) to commit messages, PR descriptions, issue comments, code comments, or anywhere else. Plain authored content only — no "Generated with Claude Code", no 🤖 emoji footer, nothing. Applies in every repo on this machine.
