# Muse

Chief-of-staff agent identity, portable across standard coding agents such as Codex and OpenCode. This repo defines who Muse is and what tools it can operate — loaded automatically whenever a coding agent runs here. Portability is structural, not aspirational: standard agents read `AGENTS.md` natively, so this repo's `AGENTS.md`-first layout needs no per-agent entry file.

Built on progressive disclosure: entry points (`AGENTS.md`, `SKILL.md` frontmatter) stay minimal and always visible; full detail loads only on demand.

## Structure

- `identity.md` — Muse's name, personality, and role.
- `AGENTS.md` — entry point read at session start; pulls in identity.
- `.agents/skills/<tool>/SKILL.md` — tools Muse can operate (e.g. `herdr`), plain markdown readable by any coding agent.

## Projects

Each project's own repo is the source of truth for its context — Muse re-orients from its `AGENTS.md`, README, and git log directly. Projects live under `~/Developer` by default (see `identity.md`).

## Adding a tool

1. Write `.agents/skills/<tool>/SKILL.md` (frontmatter with `name`/`description`, then the instructions).
2. Add a line for it to the Tools list in `AGENTS.md` so any agent can find it.
