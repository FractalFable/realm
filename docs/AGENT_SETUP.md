# Agent & MCP Setup

This repository is used with both **Antigravity** and **Claude Code**. Their plugin/MCP configurations are separate, so tooling must be enabled per client.

## Dart & Flutter

### Claude Code
1. **MCP Server**: Check that the `dart` MCP server is available (`claude mcp list` or `.mcp.json`). If it is missing and the task involves Dart or Flutter, prompt the user to add it:
   ```bash
   claude mcp add dart -- dart mcp-server
   ```
   *(Requires Dart/Flutter SDK 3.13+ installed locally.)*
2. **Skills (optional)**: Antigravity's `Dart and Flutter` plugin installs `SKILL.md` files under `~/.gemini/config/plugins/flutter/skills/`. If you want those same skills available in Claude Code, symlink or copy them into `~/.claude/skills/` (or `.claude/skills/` in this repo).

### Antigravity
- Install the official **Dart and Flutter** plugin (`antigravity-plugins-official/plugin/flutter`) from the Marketplace. It bundles the `dart-mcp-server`, Flutter/Dart skills, rules, and `flutter_a11y_agent`.

## Other Tools & Stack MCPs

Keep `.mcp.json` minimal (or opt-in) so unused tool schemas don't bloat every session's context. When starting a session on a specific app or stack, check whether the relevant MCP or plugin is enabled before falling back to manual CLI workarounds:

| Capability | Antigravity | Claude Code | Notes |
| :--- | :--- | :--- | :--- |
| **Browser / Web UI** | Built-in `browser` subagent | `claude mcp add playwright -- npx -y @playwright/mcp@latest` | Opt-in for Flutter Web / web apps |
| **Database** | Stack-specific (e.g. **Supabase** plugin or local Postgres MCP) | `postgres-mcp` (`--access-mode=restricted`) or provider MCP | Opt-in; prefer read-only roles locally |
| **Containers** | `docker` MCP (`uvx mcp-server-docker`) | `claude mcp add docker -- uvx mcp-server-docker` | Opt-in when running Docker Compose |
| **Web frameworks** | Stack-specific (e.g. `next-devtools`) | `claude mcp add next-devtools -- npx -y next-devtools-mcp@latest` | Opt-in per web app |
| **GitHub** | `github` MCP or `gh` CLI | `github` MCP or `gh` CLI | Opt-in for PRs, issues, and Actions |

## Maintaining `AGENTS.md`
- **Keep root [`AGENTS.md`](../AGENTS.md) lean**: treat it strictly as a table of contents ("kazalo") that links out to concrete files in `docs/` with a one-line note on when to read each.
- **No inline bloat**: when adding new workflows, architecture notes, or tool rules, write a dedicated file under `docs/` and add a link to it in `AGENTS.md`.
- **Scope rules locally**: put app- or stack-specific instructions in `<app>/AGENTS.md` so they only load when working in that subdirectory.
