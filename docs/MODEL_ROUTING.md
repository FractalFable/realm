# Model Routing

Shared model tier policy for multi-agent work, code reviews, fixes, and self-improvement evals across **Gemini** and **Claude**. Concrete model IDs live **only** in this file so upgrading to newer releases is a single-file change.

*Last verified: 2026-11-22*

## 4-Tier Model Ladder

| Tier | Scope / Risk | Gemini | Claude |
| :--- | :--- | :--- | :--- |
| **Tier 1 (Lowest)** | Docs, formatting, triage, mechanical fixes | `gemini-4-hydrogen-medium` *(Hydrogen Medium)* | `claude-sonnet-5-5-medium` *(Sonnet Medium)* |
| **Tier 2 (Low-Mid)** | UI, theming, lints, standard fixes | `gemini-4-hydrogen-high` *(Hydrogen High)* | `claude-sonnet-5-5-high` *(Sonnet High)* |
| **Tier 3 (High-Mid)** | Business logic, domain, API, DB, deps, A/B evals | `gemini-4-neon-medium` *(Neon Medium)* | `claude-opus-5-5-medium` *(Opus 5 / Opus Medium)* |
| **Tier 4 (Highest)** | Payments, POS/fiscal, auth, security, prod + human sign-off | `gemini-4-neon-high` *(Neon High)* | `claude-opus-5-5-high` *(Opus High)* |

## Minimum Floor Rule

- Never downgrade below **Tier 1** (`gemini-4-hydrogen-medium` on Gemini or `claude-sonnet-5-5-medium` on Claude).
- Do **not** use legacy Flash, Flash Lite, or Haiku models for any tier.

## Fail-Safe for Other or Unavailable Models

Before spawning workers or subagents:
1. Check which models are available in the active environment (in Antigravity, run `swarm(action: "models", all: true)`).
2. If the session is running on another provider/model family (e.g., OpenAI, local/OSS models, or unrecognized/newer model names), or if any tier's configured model is unavailable:
   - **Stop and ask the user** which models to assign to **Tier 1 (Lowest)**, **Tiers 2–3 (Middle)**, and **Tier 4 (Highest)** before proceeding.
   - Never silently fall back to weaker or unapproved models.

## Keeping Models Up to Date (Model Refresh)

When `swarm(action: "models", all: true)` shows newer Gemini or Claude models than the table above, a listed model is deprecated/removed, or the user asks to refresh models:
1. [`agent-improver`](../.agents/agents/agent-improver.md) invokes [`web-researcher`](../.agents/agents/web-researcher.md) to verify current Gemini & Claude releases and tier equivalents as of today's date.
2. `agent-improver` drafts the updated 4-tier table (preserving the minimum floor and ceiling intent) and presents a concise **Approval Summary** (Current vs. Proposed table + release notes).
3. Upon user approval, `agent-improver` updates this file and its `Last verified` date in one step.

## Harness Note (Antigravity)

- `swarm` is available only to the main/coordinator agent (never list `swarm` in `.agents/agents/*.md` `tools:` frontmatter). Calling `invoke_subagent(Model: "inherit")` from a Tier 3–4 coordinator executes Tier 1–2 agents (`doc-writer`, `web-researcher`, Tier 1–2 `code-reviewer`) at Tier 3–4 cost; prefer `swarm(action: "add", model: "<Tier 1/2 ID>")` when delegating substantial Tier 1–2 work from a higher-tier coordinator.
- Custom subagents (`mainAgent: true` or `subagent: true`) without `swarm` rely on coordinator-passed context or dispatch child workers via `invoke_subagent`, whose `Model` argument only exposes coarse presets (`inherit`, `flash_lite`, `flash`, `pro`). **Never pass `flash_lite` or `flash`**; pass `inherit` (only when the parent session already meets or exceeds the target tier's floor) or `pro`, and call `ask_question` if active provider or tier compliance is uncertain.
