# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# host notes (machine-local memory)
`~/.claude/host-notes.md` is this machine's local memory — **not** synced via chezmoi, **not** committed to any repo, **not** shared. When the user says "host notes" they mean this file. Read it at session start if it exists, and append host-specific facts (paths, tool versions, machine-only context) when asked. Never copy its contents into a repo, a commit, a PR, or any shared channel.
