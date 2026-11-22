# Project Overview

**Realm** is an open-source monorepo of completely brand-agnostic apps (**Tavern** for pub and restaurant management, **Grimoire** for E2EE interactive note taking, more to follow) built on shared, app-neutral `realm_*` packages. Each operator runs their own instance and retains full control over branding, integrations, and infrastructure.

## Applications in Realm

- **Tavern** ([docs/apps/TAVERN.md](apps/TAVERN.md)) — Standalone, white-label pub and restaurant management suite (`tavern_staff`, `tavern_guest`, `tavern_server`) powered by `realm_ui`, `realm_a2ui`, `realm_server_kit`, and `tavern_*` domain/protocol/feature packages.
- **Grimoire** ([docs/apps/GRIMOIRE.md](apps/GRIMOIRE.md)) — Multi-platform (iOS, Android, macOS, Web), end-to-end encrypted interactive note-taking app (`grimoire`, `grimoire_server`) featuring rich blocks, bi-directional note links, sandboxed web embeds, cross-platform runnable scripts, local-first hybrid RAG, and A2UI.
- **Future Apps** — Additional apps added under `apps/<name>` share the same app-neutral `packages/realm_*` building blocks without coupling product domains together.

## Scope-Based Package Naming

- **`packages/realm_*`**: Strictly app-neutral platform packages safe for any app to depend on (`realm_core`, `realm_ui`, `realm_lints`, `realm_server_kit`, `realm_a2ui`, `realm_crypto`, `realm_protocol`, `realm_client`, `realm_auth`, `realm_vault`).
- **`packages/<app>_*`**: Product-specific domain, protocol, or feature libraries (`tavern_core`, `tavern_protocol`, `tavern_<feature>`, `grimoire_core`).
- **`apps/`**: Thin deployable client shells and per-app servers (`tavern_server`, `tavern_staff`, `tavern_guest`, `grimoire_server`, `grimoire`).

## Core Principles

- **Bring Your Own Branding (White-Label)**: Operators supply their own branding—name, logos, colors, themes, domain, and copy/assets—at runtime (see [`docs/CONFIG_AND_SECRETS.md`](CONFIG_AND_SECRETS.md)). Core apps and packages must remain completely white-label.
- **Bring Your Own API Keys (BYOK)**: Third-party integrations and optional features are powered by the operator's own backend-stored API keys, never hardcoded, committed, or shipped in client binaries.
- **Self-Hosted (Bring Your Own Hosting)**: The platform is designed to be deployed and operated on the user's own hosting and infrastructure, with no lock-in to a single cloud vendor or managed service.

## Strict Brand-Agnostic Rule

- **Zero fixed brands or external project references**: No files in this repository (code, tests, docs, comments, agent prompts, or commit messages) may mention any fixed venue/customer brand or any external private/test project.
- **Zero hardcoded URLs or brand strings in `lib/`**: All server endpoints, branding values, and keys enter through runtime/build configuration (`ClientEndpointConfig`, `AppBootstrap` / `VenueBootstrap`, backend config/vault).
- **Generic placeholders only in docs/tests**: Use neutral placeholders like `Example Venue`, `Example Realm`, and `example.com` when illustrating tests or documentation.

## Implications for Agents & Contributors

- Keep branding, copy, and visual assets configurable/overridable across all apps and packages.
- Keep `packages/realm_*` strictly app-neutral; never import `tavern_*` or `grimoire_*` from `realm_*`, and put product-specific logic in `<app>_*`.
- Externalize all third-party service credentials on the backend (`IntegrationKeyStatus` for UI status only), with safe gating (`AppCapabilities` / `VenueCapabilities`) when a key is omitted.
- Avoid coupling deployment scripts, networking, or storage assumptions to a single proprietary host; keep infrastructure portable (standard containers, configurable URLs, and storage paths).
