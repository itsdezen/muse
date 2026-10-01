---
name: herdr
description: Use when checking, launching, prompting, or shutting down AI coding agents in terminal panes/workspaces via herdr. Code changes stay with Muse unless explicitly delegated.
---

# herdr

Terminal workspace multiplexer for running and orchestrating coding-agent CLIs side by side. CLI: `herdr`.

**herdr agents are persistent staff; Task-tool agents are ephemeral research.** Use `herdr agent start` for staff that must be inspectable, promptable, or outlive this turn.

## Preflight

Run `herdr status` first. If the server is not running, ask before starting a persistent herdr session unless the user explicitly asked to work inside herdr.

## Safety invariants

- Record the current Muse pane ID when it is known (`MUSE_PANE_ID` or the launcher integration's pane metadata). Exclude that exact pane so Muse is not counted as staff.
- If the current pane ID is unavailable, mark current-session identity as unverified and report pane-level findings without claiming an exact staff count.
- Use the pane ID as the canonical target. A name is reliable only when it is the explicit name passed to `herdr agent start`; the detected CLI kind shown by `agent list` is not necessarily a target name.
- Start OpenCode staff with its native Build agent. Normal mode asks before edits and shell commands. `--auto` auto-approves every request and is effectively full access, not a safety classifier.
- Keep staff scope narrow. Leave commits, pushes, deploys, and destructive commands to Muse unless explicitly assigned.
- Use `--auto` only when the user explicitly approves an unattended run in a trusted repository. OpenCode does not sandbox shell commands, so a worktree makes source changes recoverable but does not contain system, network, credential, push, or deployment effects.
- Run unattended or concurrent write-capable staff in a dedicated worktree. Muse decides scope before launch and reviews the final diff afterward.

## Survey → narrow → inspect → act

1. **Survey:** `herdr workspace list`. Treat `working` as active work, not as a reason to stop; inspect any workspace that is not known to contain only the current Muse pane.
2. **Narrow:** `herdr pane list --workspace <id>` or `herdr agent list`. Save the pane ID and explicit agent name for the target. Do not use the detected kind as the target.
3. **Inspect:** `herdr pane get <pane_id>` and `herdr agent read <pane_id> --lines 40`.
4. **Act by state:**
   - `working`: do not prompt; wait with `herdr agent wait <pane_id> --until idle --until blocked --until done --until unknown --timeout 120000`.
   - `idle`: prompt with a bounded wait: `herdr agent prompt <pane_id> "<instruction>" --wait --until idle --until done --until blocked --timeout 120000`.
   - `blocked`: read the pane, then resolve the approval with `herdr agent send-keys`; `agent prompt` rejects blocked agents.
   - `done`: read the final output and verify the requested result before cleanup.
   - `unknown` or timeout: inspect and read output; do not blindly resend the prompt.

`idle` is a normal completion state for OpenCode, so waiting only for `done` can hang. A timeout is a diagnostic outcome, not proof that the task failed. Always verify the final output and repository state.

## Starting staff

- For isolated work, run `herdr worktree create --cwd <project-path> --branch <name> --base <ref> --no-focus`; use the returned `root_pane.pane_id` directly rather than splitting another pane.
- For supervised work that does not need isolation, create a pane with `herdr pane split --pane <muse-pane-id> --direction right|down --cwd <project-path>`.
- Supervised OpenCode: `herdr agent start <name> --kind opencode --pane <staff-pane-id> -- --agent build`
- User-approved full access: `herdr agent start <name> --kind opencode --pane <staff-pane-id> -- --agent build --auto`
- For multi-checkpoint work, set stable metadata: `herdr pane report-metadata <pane_id> --source muse --display-agent "<label>" --token task=<slug>`.
- Choose the model from the installed provider configuration. OpenCode model IDs use `provider/model`; verify authentication before assuming an ID.
- Use `herdr agent attach <target> [--takeover]` when the user wants direct keyboard control.

## Completion and cleanup

After reading the final output, verify `git status --short` and the complete diff, then close completed staff panes with `herdr pane close <pane_id>`. Never close a `working` or `blocked` pane without confirmation or explicit user direction. Clear metadata before reusing a long-lived pane.

## Reference commands

- Discover: `herdr workspace list`, `herdr tab list --workspace <id>`, `herdr pane list --workspace <id>`, `herdr agent list`, `herdr agent explain <pane_id>`
- Control: `herdr agent wait`, `herdr agent prompt`, `herdr agent send-keys`, `herdr agent focus`, `herdr agent rename`
- Teardown: `herdr pane close <pane_id>`, `herdr tab close <tab_id>`, `herdr workspace close <workspace_id>`
- Full state: `herdr api snapshot` only when the survey is insufficient

Use `herdr agent start --help` for the installed kind list; do not rely on a version-specific list in this document.
