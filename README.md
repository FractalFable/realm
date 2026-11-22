# Realm

An open-source monorepo of white-label apps built with **Dart** and **Flutter** that share common building blocks:

- **Tavern** ([docs/apps/TAVERN.md](docs/apps/TAVERN.md)) — Pub and restaurant management suite (`tavern_staff`, `tavern_guest`, `tavern_server`) with A2UI staff copilot and guest discovery.
- **Grimoire** ([docs/apps/GRIMOIRE.md](docs/apps/GRIMOIRE.md)) — Multi-platform (iOS, Android, macOS, Web), end-to-end encrypted interactive note-taking app (`grimoire`, `grimoire_server`) with bi-directional links, web embeds, sandboxed scripts, local-first RAG, and A2UI.
- More apps may follow, sharing the same app-neutral `realm_*` foundation.

Operators deploy Realm apps on their own infrastructure and customize branding, third-party integrations, and hosting with zero hardcoded venue logic or vendor lock-in.

## Setting Up With an AI Agent

Most operators will hand this repository to an AI coding agent rather than configuring files by hand. Follow this runbook when setting up an instance:

1. **Verify workspace status first**:
   - Implemented: `packages/realm_core`, `packages/realm_ui`, `packages/realm_lints`, and `./scripts/check.sh`.
   - Planned / scaffolding in progress: `packages/tavern_core`, `packages/grimoire_core`, `packages/realm_server_kit`, `packages/realm_a2ui`, `packages/realm_crypto`, `packages/realm_protocol`, `packages/realm_client`, `packages/realm_auth`, `packages/realm_vault`, and `apps/` (`tavern_server`, `tavern_staff`, `tavern_guest`, `grimoire_server`, `grimoire`).
   - Read [`AGENTS.md`](AGENTS.md) and [`docs/CONFIG_AND_SECRETS.md`](docs/CONFIG_AND_SECRETS.md) before configuring anything.
2. **Collect operator inputs** (ask once in one message):
   - Hosting target & backend domain (HTTPS required outside local loopback `localhost` / `127.0.0.1` / `::1`).
   - Runtime branding (`name`, `primaryColorArgb`, optional `tagline`, optional `https://` `logoUrl`).
   - Optional BYOK integrations to enable (`aiLlm`, `payments`, `posFiscal`, `email`, `sms`—skip any unconfigured ones; Realm boots cleanly without them).
3. **Configure secrets & endpoints safely**:
   - Generate infrastructure secrets (`DATABASE_URL`, `JWT_SIGNING_KEY`, `REALM_MASTER_KEY`) directly on the server/secret store without printing raw values into chat.
   - Store client-side build overrides only in gitignored files (`venue.json`, `config.local.json`) or runtime `/config.json`—never hardcode URLs, brands, or API keys in `lib/`.
4. **Verify**:
   ```bash
   flutter pub get && ./scripts/check.sh
   ```
   Expected: `No issues found!` and all workspace tests passing.

## Core Principles

- **Bring Your Own Branding (White-Label)** — Instance name, colors, logo, tagline, and domain are supplied at runtime via `GET /api/v1/bootstrap`, never hardcoded into builds.
- **Bring Your Own API Keys (BYOK)** — Optional AI, payment, POS/fiscal, email, and SMS integrations use the operator's own backend credentials stored envelope-encrypted at rest (never shipped in client binaries).
- **Self-Hosted (Bring Your Own Hosting)** — Run the backend and database on any VPS, container host, or on-premise server.

## Repository Layout

This repository uses **Dart Pub Workspaces** (`sdk: ^3.14.0`, Flutter `>=3.50.0`) with scope-based naming:

- `packages/realm_*` — App-neutral shared platform libraries (`realm_core`, `realm_ui`, `realm_lints`, and planned `realm_server_kit`, `realm_a2ui`, `realm_crypto`, `realm_protocol`, `realm_client`, `realm_auth`, `realm_vault`).
- `packages/<app>_*` — Product-specific libraries (`tavern_core`, `tavern_protocol`, `tavern_<feature>`, `grimoire_core`).
- `apps/` — Deployable clients and per-app servers (`tavern_server`, `tavern_staff`, `tavern_guest`, `grimoire_server`, `grimoire`).
- `scripts/check.sh` — Deterministic pre-review gate (`dart format`, `dart analyze`, hygiene checks, and workspace tests).
- `docs/` — Architecture, configuration, workflow, app specs, and agent runbooks.

## Documentation

- [Project Overview](docs/PROJECT_OVERVIEW.md) — Multi-app goals and strict brand-agnostic rules.
- [Architecture Decisions](docs/ARCHITECTURE.md) — Backend, database, state, routing, package boundaries, testing, and open operator decisions.
- [Tavern Architecture](docs/apps/TAVERN.md) — White-label pub/restaurant management apps and A2UI workflows.
- [Grimoire Architecture](docs/apps/GRIMOIRE.md) — E2EE interactive notes, local-first RAG, A2UI, and sandboxed scripting.
- [Config, Branding & BYOK Secrets](docs/CONFIG_AND_SECRETS.md) — Endpoint resolution, `/api/v1/bootstrap`, and server-only BYOK secret storage.
- [Monorepo & Linting](docs/MONOREPO.md) — Dart Pub Workspace setup and shared `realm_lints` rules.
- [A2UI Architecture Note](docs/A2UI.md) — Declarative generative UI (`a2ui_flutter` / `a2ui_core`) evaluation.
- [AI Efficiency & Autonomy](docs/AI_EFFICIENCY.md) — Deterministic gate, subagent budgets, and autonomous execution defaults.
- [Git Workflow & Branching](docs/GIT_WORKFLOW.md) — **`develop`** is the main development branch (`staging` and `production` planned).
