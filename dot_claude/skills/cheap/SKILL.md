---
name: cheap
description: Turn on /cheap mode for the current session, which keeps it from ever pushing the account's usage windows (5h, weekly, model-scoped weekly) past 99% and resumes when they reset. Use when the user types `/cheap`, `/cheap on`, `/cheap off`, `/cheap status`, or `/cheap <task>`, or asks to turn on cheap mode or keep the session under its usage limit. Claude Code only — enforced by the cheap-guard hooks.
argument-hint: "[on | off | status | task — optional]"
---

# cheap

The cheap-guard hook has already applied this command; when it reported the
mode, that line is in the hook context. While the mode is on, the hooks hold
any model call (subagents, workflows and compaction included) that might
push a usage window past 99%, and release it once there is room.

Arguments: $ARGUMENTS

- **None, `on`, `off` or `status`:** state the mode in one line, then resume
  whatever was in progress before this command. Start nothing new.
- **Anything else:** that is the task; carry it out.

Invoking this skill as the agent only ever turns the mode on; only the user
can turn it off.
