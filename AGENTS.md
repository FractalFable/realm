# AGENTS.md

Monorepo for multiple apps (primarily Dart & Flutter, plus supporting tools). Keep this file minimal; read the linked docs on demand when relevant to the task.

## Docs Index
- [Project Overview](docs/PROJECT_OVERVIEW.md) — Open-source, brand-agnostic pub/restaurant management goals (white-label, BYOK, self-hosting).
- [Config, Branding & BYOK Secrets](docs/CONFIG_AND_SECRETS.md) — Runtime endpoint resolution, `/api/v1/bootstrap`, and server-only encrypted BYOK storage.
- [Monorepo & Linting](docs/MONOREPO.md) — Dart Pub Workspace layout, shared `realm_lints` presets, and workspace commands.
- [A2UI Architecture Note](docs/A2UI.md) — A2UI 1.0 (`a2ui_flutter` / `a2ui_core`) evaluation and white-label/BYOK boundaries.
- [AI Efficiency & Autonomy](docs/AI_EFFICIENCY.md) — Pre-review deterministic checks (`./scripts/check.sh`), token hygiene, and high-autonomy defaults.
- [Model Routing](docs/MODEL_ROUTING.md) — Gemini & Claude 4-tier model ladder, minimum floor, and unknown-provider fail-safe.
- [Code Review Policy](docs/REVIEW_POLICY.md) — 4-tier risk-based review routing, severity thresholds, and fix routing.
- [Agent Improvement & Evals](docs/AGENT_IMPROVEMENT.md) — Autonomous trigger rules, A/B testing ("improve only"), and summary approval flow.
- [Agent & MCP Setup](docs/AGENT_SETUP.md) — Read only when a required MCP/plugin is missing or onboarding a new stack/IDE (Antigravity vs. Claude Code).
- [Git Workflow & Branching](docs/GIT_WORKFLOW.md) — Branch structure (`develop` as main branch; planned `staging` and `production`).

## Conventions
- Scope app/stack rules in `<dir>/AGENTS.md` rather than crowding this root index.
- `doc-writer` owns `README.md`, `AGENTS.md`, and general `docs/` updates (batch multi-file or substantive doc work; tiny `<= 2` file / `< 30` line syncs may be edited directly following `doc-writer`'s rules).
- `agent-improver` owns `.agents/**` and agent-ops policy docs (`docs/MODEL_ROUTING.md`, `docs/REVIEW_POLICY.md`, `docs/AGENT_IMPROVEMENT.md`) under its trigger and approval gates.
- Run `./scripts/check.sh` (format, analyze, hygiene, tests) before `code-reviewer`, and follow high-autonomy defaults in [AI Efficiency & Autonomy](docs/AI_EFFICIENCY.md).
