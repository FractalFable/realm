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
- [Agent & MCP Setup](docs/AGENT_SETUP.md) — **Read at session start** when working with Dart/Flutter or setting up MCPs/plugins (includes separate Antigravity vs. Claude Code checks).
- [Git Workflow & Branching](docs/GIT_WORKFLOW.md) — Branch structure (`develop` as main branch; planned `staging` and `production`).

## Conventions
- Add per-app or per-stack `AGENTS.md` files inside their respective subdirectories rather than crowding this root file.
- Route all `README.md` and `docs/` updates to `doc-writer` (agent-first runbook style).
- Always run `./scripts/check.sh` (format, analyze, tests) before invoking `code-reviewer`, and follow the high-autonomy defaults in [AI Efficiency & Autonomy](docs/AI_EFFICIENCY.md).
- Proactively invoke `agent-improver` (see [Agent Improvement & Evals](docs/AGENT_IMPROVEMENT.md)) when a user corrects agent behavior, recurring review/setup friction appears, or docs/agents drift—and present its summary for user approval when gated by [Agent Improvement & Evals](docs/AGENT_IMPROVEMENT.md).
