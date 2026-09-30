---
name: herdr
description: Use when checking on, launching, prompting, or shutting down AI coding agents running in terminal panes/workspaces via the herdr multiplexer, or when the user mentions "herdr", other running agents, or wants a dedicated pane/workspace for a project. Scoped to orchestrating agent panes — code edits stay with the main agent.
---

# herdr

Terminal workspace multiplexer for running and orchestrating multiple AI coding agent CLIs (Claude Code, Codex, Gemini, Cursor, OpenCode, etc.) side by side in one terminal — locally or over SSH. Home: https://herdr.dev. CLI: `herdr`.

**herdr agents, not Claude Code subagents.** "Spawn/manage an agent" always means a real `herdr agent start` process in its own pane — never the Agent/Task tool. A Task subagent is ephemeral, lives only inside this session's context window, and doesn't exist as far as `herdr` is concerned; it can't be listed, prompted later, or checked on after this session ends. If the user wants an agent running work in parallel that they can check on, hand off to, or that should outlive this conversation, it must go through `herdr agent start`, not Agent/Task.

## Preflight — always do this first
`herdr status` — if `server: not running`, no session is up yet. Starting one (`herdr` or `herdr --session <name>`) launches a persistent background daemon that outlives this shell. Confirm with the user before starting a new session, unless they've already asked you to work inside herdr.

## Concepts
- Hierarchy: **workspace** → **tab** → **pane** → **agent**. A pane is a terminal; an agent is a supported CLI detected running inside a pane.
- Status rolls up: every pane/agent has `agent_status` (`idle | working | blocked | done | unknown`); tabs and workspaces report the same field as a rollup of everything inside them. Checking a workspace tells you if *anything* inside needs attention without opening a single pane.
- Targets: `agent`/`pane` commands take a `<target>` — a pane_id or agent name from `list`/`get`. Always look it up first; IDs are per-session.
- **"Session" means two different things here** — herdr's own `--session <name>` server namespace (see Beyond panes, below) versus a coding agent's own conversation session (what `agent_session.value` refers to, e.g. a Claude Code session id). _Avoid_ saying "session" unqualified when either could be meant — say "herdr session" or "the agent's session" explicitly.
- **Exclude the current session from status reports.** This very session (Muse) shows up in `herdr agent list`/`workspace list` as its own entry (matching `agent_session.value` to this session's id, kind `claude`, cwd of this repo). Filter it out before reporting to the user, treating it as outside the report entirely. If it's the only entry, report "no other agents running."

## Beyond panes — the rest of herdr's model
Panel splitting covers routine staff spawning, but herdr models more than that. Reach for these only when the specific problem actually calls for them — the split+swap panel rule in identity.md stays the default for ordinary staff work.

- **Session** (`--session <name>` at startup) is a separate server namespace — its own daemon, own state, invisible to other sessions. Stay in the single default session; only start a second one if the user explicitly wants fully isolated runtime state (a different machine/context), not just another project.
- **Worktree** (`herdr worktree create --branch NAME [--base REF]`) gives a staff member its own git checkout + workspace. Reach for this when two or more staff need concurrent uncommitted changes in the *same* repo — plain `pane split` with a shared cwd is fine when only one staff touches that repo at a time, or staff are in different repos/subdirs.
- **Status labels** (`herdr pane report-metadata <pane_id> --source muse --display-agent "<label>" --token task=<slug>`) let the herdr sidebar carry a stable description of what a staff member is for, independent of its own fluctuating per-turn terminal title. Worth setting right after briefing a staff member on anything spanning multiple checkpoints (the common case when babysitting) — skip it for quick one-off asks. Verified working: sets `display_agent` and `tokens` on the pane, visible via `pane get`.
- **Direct attach** (`herdr agent attach <target> [--takeover]`) lets *the user* take the keyboard directly on a staff pane instead of going through Muse's relay. Mention this to the user if they want to jump in themselves rather than wait on Muse to relay each prompt.
- Declarative layout export/apply (BSP trees) exists at the socket-API level but isn't exposed via the `herdr` CLI as of v0.8.0 — the pane split+swap approach already in identity.md's panel-layout rule is the right-sized tool for today's 2-row layout; there's no CLI shortcut to reach for yet.

## Orchestration workflow — survey → narrow → inspect → act
Go narrower only as needed, and stop as soon as you have the answer:

1. **Survey** (cheapest): `herdr workspace list` — one line per workspace with rolled-up `agent_status`. If everything reads idle/working and nothing needs you, stop here.
2. **Narrow**: `herdr tab list --workspace <id>` or `herdr agent list` — find exactly which tab/pane/agent is `blocked` or `done`.
3. **Inspect**: `herdr agent get <target>` for metadata, or `herdr agent read <target> --lines 40` for recent output — read only the one agent that needs attention, not everyone's.
4. **Act**: `herdr agent prompt <target> "<instruction>" --wait --until done` to send input and block until it settles, or `herdr agent wait <target> --until blocked done` to poll without sending anything. Prompting while `agent_status: working` queues input into an agent mid-turn — confirm that's intended, or wait for `idle`/`blocked` first, rather than doing it as a matter of course.

Reach for `herdr api snapshot` only if you genuinely need the full picture at once — it dumps the entire session state (every workspace/tab/pane/agent) in one shot, so the survey→narrow→inspect→act sequence above is the default.

## Choosing a model when spawning an agent
Both major providers organize models into the same three tiers — match the tier to the task, not the provider brand. Sources: Anthropic's model catalog (`shared/models.md` in the `claude-api` skill) and OpenAI's Codex docs (developers.openai.com/codex/models, developers.openai.com/api/docs/guides/model-selection).

| Tier | `--kind claude` | `--kind codex` | Use for |
|---|---|---|---|
| Flagship / deep reasoning | Opus 4.8 (`claude-opus-4-8`) — highly autonomous, state-of-the-art long-horizon agentic work; Fable 5 (`claude-fable-5`) for the hardest long-horizon work if the user explicitly wants max capability | GPT-5.6 Sol — "strongest capability for complex coding, computer use, research" | Long autonomous coding runs, architecture/planning, ambiguous or high-stakes work, deep debugging |
| Balanced everyday | Sonnet 5 (`claude-sonnet-5`) — near-Opus quality on coding/agentic at Sonnet cost | GPT-5.6 Terra — "the everyday workhorse" | Interactive quick edits, day-to-day coding, most tasks — the default choice |
| Fast / cheap | Haiku 4.5 (`claude-haiku-4-5`) | GPT-5.6 Luna — "strong capability at the lowest cost" | High-volume simple tasks: classification, extraction, quick lookups, structured repeatable work |

- **Model catalogs move fast** (new generations every few months) — always check the current catalog: `shared/models.md` in the `claude-api` skill for Claude, `codex debug models` or developers.openai.com/codex/models for Codex.
- **Passing the model through `herdr agent start`**: the trailing `-- [AGENT_ARG]...` forwards args to the underlying CLI, e.g. `herdr agent start work1 --kind claude --pane p1 -- --model claude-opus-4-8` or `... --kind codex --pane p1 -- --model gpt-5.6-sol`. Both CLIs also support switching mid-session (`/model`) once attached.
- Default to the balanced tier unless the task clearly calls for more depth or is simple/high-volume — same "start simple, escalate only when needed" principle as everywhere else in this guide.
- **`--kind opencode` doesn't fit this table** — OpenCode is a multi-provider gateway, not one vendor's fixed catalog. Model flag format is `--model provider/model` (e.g. `--model anthropic/claude-opus-4-8`); which `provider/model` pairs actually work depends on what's been authenticated via `opencode auth login` on this machine, not a small enumerable list like the table above — check current availability rather than assuming an ID from another CLI's catalog carries over. Example: `herdr agent start work1 --kind opencode --pane p1 -- --model anthropic/claude-opus-4-8`. Same balanced-by-default principle still applies — just pick the tier from whichever provider is actually configured.

## Command cheat sheet

Discover:
- `herdr workspace list` / `herdr tab list [--workspace ID]` / `herdr pane list [--workspace ID]` / `herdr agent list`
- `herdr agent get <target>` · `herdr pane get <target>` · `herdr agent explain [target]` (why an agent was/wasn't detected)

Create:
- `herdr workspace create [--cwd PATH] [--label TEXT]`
- `herdr tab create [--workspace ID] [--cwd PATH] [--label TEXT]`
- `herdr pane split [--pane ID] [--direction right|down] [--cwd PATH]`
- `herdr agent start <NAME> --kind <KIND> --pane <ID>` — pane must already be sitting at an interactive shell prompt
- `herdr worktree create --branch NAME [--base REF] [--workspace ID]` — new git worktree in its own workspace

Control an agent:
- `herdr agent prompt <target> "<text>" [--wait] [--until STATUS...] [--timeout MS]`
- `herdr agent wait <target> [--until STATUS...] [--timeout MS]`
- `herdr agent send-keys <target> <keys...>` — raw keypresses, for things `prompt` can't express (e.g. approving a y/n)
- `herdr agent focus <target>` / `herdr agent rename <target> <name>`
- `herdr agent attach <target> [--takeover]` — for telling the user how to take the keyboard directly themselves
- `herdr pane report-metadata <pane_id> --source muse [--display-agent TEXT] [--token NAME=VALUE] [--clear-display-agent] [--clear-token NAME]` — optional stable status label for the sidebar

Teardown:
- `herdr pane close <pane_id>` · `herdr tab close <tab_id>` · `herdr workspace close <workspace_id>`
- Closing kills the process inside. Confirm before closing a pane/tab/workspace whose agent is mid-turn (`agent_status: working`).

## Notes
- `list`/`get` commands print human-readable text by default — `herdr api snapshot --output PATH` is the one place to get the full JSON tree if truly needed.
- Supported `--kind` values for `agent start` (v0.7.5): pi, claude, codex, gemini, cursor, devin, agy, cline, omp, mastracode, opencode, copilot, kimi, kiro, droid, amp, grok, hermes, kilo, qodercli, maki.
