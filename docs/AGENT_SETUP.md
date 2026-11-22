# Agent & MCP Setup

This repository targets **Claude Code**. Everything agent-related is committed, so a fresh clone works without per-machine setup beyond the SDKs.

## What Is Committed

| File | Purpose |
| :--- | :--- |
| [`CLAUDE.md`](../CLAUDE.md) | Imports `@AGENTS.md`; holds `## Learned Constraints` from self-improvement runs |
| [`packages/realm_ui/CLAUDE.md`](../packages/realm_ui/CLAUDE.md) | Imports the package's scoped `AGENTS.md` (Claude Code loads nested `CLAUDE.md`, not nested `AGENTS.md`). Add one per new `apps/<app>/` too |
| [`.claude/agents/`](../.claude/agents/) | `critic`, `doc-writer`, `web-researcher`, `security-auditor`, `agent-improver` (each pins its `model`) |
| [`.claude/settings.json`](../.claude/settings.json) | Dart auto-format hook, safe command allowlist, `.env` read deny, `CLAUDE_CODE_SUBAGENT_MODEL` default |
| [`.mcp.json`](../.mcp.json) | `dart` MCP server (`dart mcp-server --enable flutter_app_lifecycle`); Claude Code asks once to approve it |
| [`.github/workflows/check.yml`](../.github/workflows/check.yml) | CI running `./scripts/check.sh --quiet`; the required check for auto-merge |

Personal overrides go in `.claude/settings.local.json` (gitignored).

## Requirements

- **Dart 3.14+ / Flutter 3.50+** on `PATH`. The format hook and the `dart` MCP server silently do nothing without it.
- **Claude Code cloud sessions** start without Flutter. Add an environment setup script that installs Flutter (stable) and runs `flutter pub get`, or `check.sh` cannot run there.
- **Skills (optional)**: Put shared Flutter/Dart `SKILL.md` files in `.claude/skills/` so every session and contributor gets them.

## Opt-In MCPs

Keep `.mcp.json` minimal so unused tool schemas don't bloat every session's context. Add these per user (`claude mcp add ...`, local scope) only when a task needs them:

| Capability | Command | Notes |
| :--- | :--- | :--- |
| **Browser (non-Flutter web)** | `claude mcp add playwright -- npx -y @playwright/mcp@latest` | Not for Flutter UIs (canvas rendering); use Dart MCP / `integration_test` |
| **Flutter E2E (native dialogs)** | `marionette_mcp` / `patrol` / `maestro` MCP | Only when `dart mcp-server`'s Flutter Driver is insufficient |
| **Database** | `postgres-mcp` (`--access-mode=restricted`) or provider MCP | Prefer read-only roles locally |
| **Containers** | `claude mcp add docker -- uvx mcp-server-docker` | When running Docker Compose |
| **GitHub** | `github` MCP or `gh` CLI | PRs, issues, Actions, auto-merge |

For live debugging, Widget Previews, and test workflows, see [Testing, Previews & Runtime Debugging](TESTING_AND_DEBUGGING.md).

## Maintaining `AGENTS.md`
- **Keep root [`AGENTS.md`](../AGENTS.md) lean**: a table of contents ("kazalo") linking to `docs/` with a one-line note on when to read each.
- **No inline bloat**: new workflows, architecture notes, or tool rules go in a dedicated `docs/` file linked from `AGENTS.md`.
- **Scope rules locally**: app- or stack-specific rules go in `<app>/AGENTS.md`, with a sibling `CLAUDE.md` containing `@AGENTS.md`.
