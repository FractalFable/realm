# AGENTS.md

Monorepo for Realm (Dart & Flutter workspace + supporting tools). **Token rule: Do NOT pre-read `docs/*.md` upfront—read only the specific doc needed for your active task.**

## Docs Index (Read On Demand Only)
- [Project Overview](docs/PROJECT_OVERVIEW.md) — Read when designing features: brand-agnostic white-label, BYOK, and self-hosting rules.
- [Config, Branding & BYOK Secrets](docs/CONFIG_AND_SECRETS.md) — Read when touching endpoints (`ClientEndpointConfig`), `/api/v1/bootstrap`, or backend secrets.
- [Monorepo & Linting](docs/MONOREPO.md) — Read when adding packages/dependencies or configuring `realm_lints`.
- [Testing & Debugging](docs/TESTING_AND_DEBUGGING.md) — Read Sec 1–2 for unit/widget tests & Previews; Sec 3–5 only when live-debugging via DTD/VM Service or scaffolding `apps/*`.
- [A2UI Architecture Note](docs/A2UI.md) — Read only when working on generative UI (`a2ui_flutter` / `a2ui_core`).
- [AI Efficiency & Autonomy](docs/AI_EFFICIENCY.md) — Subagent context-isolation thresholds, `--quiet` deterministic gate, and autonomous PR delivery loop.
- [Model Routing](docs/MODEL_ROUTING.md) — Read only when spawning `swarm` workers or hitting model quota limits (4-tier ladder + Argon fallback).
- [Code Review Policy](docs/REVIEW_POLICY.md) — Reference for Tier 1–4 risk classification and review verdicts (`code-reviewer` is self-contained).
- [Agent Improvement & Evals](docs/AGENT_IMPROVEMENT.md) — Read only when one of the 5 drift/failure triggers fires for `agent-improver`.
- [Agent & MCP Setup](docs/AGENT_SETUP.md) — Read only when a required MCP/plugin is missing or onboarding a new IDE/stack.
- [Git Workflow & Branching](docs/GIT_WORKFLOW.md) — Branch from `develop` and autonomously open + squash-merge PRs once `./scripts/check.sh` and `code-reviewer` pass.

## Core Conventions
- **Zero fixed brands or hardcoded `lib/` URLs**: Use neutral placeholders (`Example Venue`, `example.com`); never ship BYOK secrets in clients.
- **Smart subagent delegation**: Use `code-reviewer`, `web-researcher`, `security-auditor`, and `doc-writer` (`> 3` files or `> 80` lines) to isolate noisy diffs/searches/drafts out of main chat; apply small doc syncs (`<= 3` files / `<= 80` lines) directly. Never spawn `agent-improver` on clean runs.
- **Pre-review gate**: Run `./scripts/check.sh --quiet` before `code-reviewer` and pass `check.sh: PASSED` in the brief.
