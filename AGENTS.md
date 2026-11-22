# AGENTS.md

Monorepo for Realm (Dart & Flutter workspace + supporting tools). **Token rule: Do NOT pre-read `docs/*.md` upfront—read only the specific doc needed for your active task.**

## Docs Index (Read On Demand Only)
- [Project Overview](docs/PROJECT_OVERVIEW.md) — Read when designing features: brand-agnostic white-label, BYOK, and self-hosting rules.
- [Config, Branding & BYOK Secrets](docs/CONFIG_AND_SECRETS.md) — Read when touching endpoints (`ClientEndpointConfig`), `/api/v1/bootstrap`, or backend secrets.
- [Monorepo & Linting](docs/MONOREPO.md) — Read when adding packages/dependencies or configuring `realm_lints`.
- [Testing & Debugging](docs/TESTING_AND_DEBUGGING.md) — Read Sec 1–2 for unit/widget tests & Previews; Sec 3–5 only when live-debugging via DTD/VM Service or scaffolding `apps/*`.
- [A2UI Architecture Note](docs/A2UI.md) — Read only when working on generative UI (`a2ui_flutter` / `a2ui_core`).
- [AI Efficiency & Autonomy](docs/AI_EFFICIENCY.md) — **Read before any code task**: risk-tier routing, verification loop, 2-retry circuit breaker, self-improvement, PR delivery.
- [Model Routing](docs/MODEL_ROUTING.md) — Read only when choosing a subagent model or hitting quota limits.
- [Code Review Policy](docs/REVIEW_POLICY.md) — Tier 1–4 path table, which tiers get `critic`, and on which model.
- [Agent Improvement & Evals](docs/AGENT_IMPROVEMENT.md) — Read only when one of the 5 drift/failure triggers fires for `agent-improver`.
- [Agent & MCP Setup](docs/AGENT_SETUP.md) — Read only when a required MCP/plugin is missing or onboarding a new IDE/stack.
- [Git Workflow & Branching](docs/GIT_WORKFLOW.md) — Branch from `develop`; open PRs and enable CI-gated auto-merge for Tier 1–3 only.

## Core Conventions
- **Zero fixed brands or hardcoded `lib/` URLs**: Use neutral placeholders (`Example Venue`, `example.com`); never ship BYOK secrets in clients.
- **Classify first**: Assign a risk tier (Tier 1–4) before running tools; it decides review, runtime proof, and merge rules.
- **Subagents** (`.claude/agents/`): `critic` (review), `web-researcher`, `security-auditor`, `doc-writer` (`> 3` files or `> 80` lines). Never spawn `agent-improver` on clean runs.
- **Deterministic gate first**: `./scripts/check.sh --quiet` must pass before `critic` or any runtime proof; pass `check.sh: PASSED` in the brief.
- **Circuit breaker**: Max 2 fix attempts per failing check or `critic` FAIL, then stop and report.
