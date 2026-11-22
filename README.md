# Realm

An open-source, white-label pub and restaurant management platform built with **Dart** and **Flutter**.

Operators deploy Realm on their own infrastructure and customize branding, third-party integrations, and hosting with zero hardcoded venue logic or vendor lock-in.

## Setting Up With an AI Agent

Most operators will hand this repository to an AI coding agent rather than configuring files by hand. Follow this runbook when setting up an instance:

1. **Verify workspace status first**:
   - Currently implemented: `packages/realm_core`, `packages/realm_ui`, `packages/realm_lints`, and `./scripts/check.sh`.
   - Planned (not yet scaffolded): `apps/` deployables (backend server, admin, customer apps) and container compose files.
   - Read [`AGENTS.md`](AGENTS.md) and [`docs/CONFIG_AND_SECRETS.md`](docs/CONFIG_AND_SECRETS.md) before configuring anything.
2. **Collect operator inputs** (ask once in one message):
   - Hosting target & backend domain (HTTPS required outside local loopback `localhost` / `127.0.0.1` / `::1`).
   - Venue branding (`name`, `primaryColorArgb`, optional `tagline`, optional `https://` `logoUrl`).
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

- **Bring Your Own Branding (White-Label)** — Venue name, colors, logo, tagline, and domain are supplied at runtime via `GET /api/v1/bootstrap` (`VenueBootstrap`), never hardcoded into builds.
- **Bring Your Own API Keys (BYOK)** — Optional AI, payment, POS/fiscal, email, and SMS integrations use the operator's own backend credentials stored envelope-encrypted at rest (never shipped in client binaries).
- **Self-Hosted (Bring Your Own Hosting)** — Run the backend and database on any VPS, container host, or on-premise server.

## Repository Layout

This repository uses **Dart Pub Workspaces** (`sdk: ^3.14.0`, Flutter `>=3.50.0`):

- `packages/realm_core/` — Pure Dart domain models, validation, and bootstrap/config contracts (`ClientEndpointConfig`, `VenueBootstrap`, `VenueBranding`, `VenueCapabilities`, `IntegrationKeyStatus`).
- `packages/realm_ui/` — Shared Flutter UI primitives and `VenueBranding` Material theming.
- `packages/realm_lints/` — Shared strict Dart & Flutter analyzer/linter presets.
- `apps/` — Deployable backend, staff/admin, customer apps, and supporting tools *(planned)*.
- `scripts/check.sh` — Deterministic pre-review gate (`dart format`, `dart analyze`, and workspace tests).
- `docs/` — Architecture, configuration, workflow, and agent runbooks.

## Documentation

- [Project Overview](docs/PROJECT_OVERVIEW.md) — Open-source goals and strict brand-agnostic rules.
- [Config, Branding & BYOK Secrets](docs/CONFIG_AND_SECRETS.md) — Endpoint resolution, `/api/v1/bootstrap`, and server-only BYOK secret storage.
- [Monorepo & Linting](docs/MONOREPO.md) — Dart Pub Workspace setup and shared `realm_lints` rules.
- [A2UI Architecture Note](docs/A2UI.md) — Declarative generative UI (`a2ui_flutter` / `a2ui_core`) evaluation.
- [AI Efficiency & Autonomy](docs/AI_EFFICIENCY.md) — Deterministic gate, subagent budgets, and autonomous execution defaults.
- [Git Workflow & Branching](docs/GIT_WORKFLOW.md) — **`develop`** is the main development branch (`staging` and `production` planned).
