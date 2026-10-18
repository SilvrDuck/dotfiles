---
name: cheap
description: Turn on /cheap mode for the current session, which keeps it from ever pushing the account's usage windows (5h, weekly, model-scoped weekly) past 99% and resumes when they reset. Use when the user types `/cheap`, `/cheap on`, `/cheap off`, `/cheap status`, or `/cheap <task>`. Claude Code only — enforced by the cheap-guard hooks.
argument-hint: "[on | off | status | task — optional]"
disable-model-invocation: true
---

# cheap

/cheap mode is now on for this session. The cheap-guard hooks enforce it on
every model call, including subagents, workflows and compaction, so nothing
here needs remembering: a call that might cross 99% of a usage window is held
until there is room, waiting through a window reset if needed.

Carry out the user's task as usual:

$ARGUMENTS

If the session goes quiet for a long stretch, the guard is holding; the status
line shows `cheap ⏸` with the window and its reset time.
