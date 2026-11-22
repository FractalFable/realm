# Model Routing

Shared model tier policy for multi-agent work, code reviews, fixes, and self-improvement evals across **Gemini** and **Claude**. Concrete model IDs live **only** in this file so upgrading to newer releases is a single-file change.

*Last verified: 2026-11-22*

## 4-Tier Model Ladder & Quota-Aware Fallback

| Tier | Scope / Risk | Gemini (Primary) | Gemini (Argon Quota Fallback) | Claude |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1 (Lowest)** | Docs, formatting, triage, mechanical fixes | `gemini-4-hydrogen-medium` | `gemini-4-argon-low` | `claude-sonnet-5-5-medium` |
| **Tier 2 (Low-Mid)** | UI, theming, lints, standard fixes | `gemini-4-hydrogen-high` | `gemini-4-argon-low` | `claude-sonnet-5-5-high` |
| **Tier 3 (High-Mid)** | Business logic, domain, API, DB, deps, A/B evals | `gemini-4-neon-medium` | `gemini-4-argon-medium` *(or `gemini-4-argon-low` when user-pinned)* | `claude-opus-5-5-medium` |
| **Tier 4 (Highest)** | Payments, POS/fiscal, auth, security, prod + human sign-off | `gemini-4-neon-high` | `gemini-4-argon-high` *(or `gemini-4-argon-low` when user-pinned)* | `claude-opus-5-5-high` |

## Minimum Floor & Quota Rules

- **Primary floor**: Use `gemini-4-hydrogen-medium` (Gemini) or `claude-sonnet-5-5-medium` (Claude) when primary tier quotas are available (`> 0%`).
- **Quota fallback / user-pinned Argon**: When `swarm(action: "models", all: true)` shows `0%` remaining quota on Hydrogen/Neon/Claude, or the user explicitly pins the session to **Gemini 4 Argon** (including `gemini-4-argon-low` for low-token conservation), use the Argon column without redundant model-selection prompts.
- **Forbidden legacy models**: Never use legacy Flash, Flash Lite, or Haiku (`gemini-3.8-flash-*`, `flash_lite`, `flash`, `claude-haiku-*`) for code, review, or policy work.

## Unknown-Provider Fail-Safe & Model Refresh

1. Before spawning workers via `swarm`, check `swarm(action: "models", all: true)` at most once per session.
2. If neither Primary, Argon fallback, nor Claude models have quota (or the session is on an unlisted provider like OpenAI/OSS), **ask the user once** which available models to map to Tier 1, Tiers 2–3, and Tier 4.
3. When newer Gemini/Claude releases appear in the catalog, [`agent-improver`](../.agents/agents/agent-improver.md) verifies release dates via [`web-researcher`](../.agents/agents/web-researcher.md) and presents a 1-table Approval Summary before updating this file.

## Harness Routing (Antigravity)

- **Main agent (`swarm`)**: `swarm` is available only to the main/coordinator agent. When the main agent is on Tier 3–4, use `swarm(action: "add", model: "<Tier 1/2 ID>")` to down-tier substantial Tier 1–2 work (`doc-writer`, `web-researcher`). When the main agent is already on Tier 1 or `gemini-4-argon-low`, `invoke_subagent(Model: "inherit")` runs at the same low cost without swarm board overhead.
- **Subagents (`invoke_subagent`)**: Subagents lack `swarm` and only expose coarse `Model` presets (`inherit`, `flash_lite`, `flash`, `pro`). Always pass `inherit` (or `pro` when escalating to Tier 3–4); **never** pass `flash_lite` or `flash`.
