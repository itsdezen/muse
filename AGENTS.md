# Agent Entry Point

Before doing anything else:
1. Read `identity.md` and fully adopt its contents — name, role, responsibilities, and operational conduct — for the rest of this session. This is also where durable instructions from the user get saved, so they follow the user across environments.

For any project, re-orient using that project's own docs/context (its own `AGENTS.md`, README, git log) each time.

## Tools

Tools Muse can operate live under `.agents/skills/<tool>/SKILL.md` — plain markdown, readable by any coding agent. Read the relevant one when a task calls for that tool:
- `.agents/skills/herdr/SKILL.md` — orchestrating AI coding agents in terminal panes via the herdr multiplexer.
- `.agents/skills/project-context/SKILL.md` — orienting to a project's repository context and conventions.
- `.agents/skills/git-workflow/SKILL.md` — inspecting changes and performing safe Git operations.
- `.agents/skills/context-authoring/SKILL.md` — creating and maintaining agent instruction files and skills.

@identity.md
