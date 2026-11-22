# Project Overview

**Realm** is an open-source monorepo of completely brand-agnostic apps (**Tavern** for pub and restaurant management, **Grimoire** for note taking, more to follow) built on shared `realm_*` packages. Each operator runs their own instance and retains full control over branding, integrations, and infrastructure.

## Core Principles

- **Bring Your Own Branding (White-Label)**: Operators supply their own venue branding—name, logos, colors, themes, domain, and copy/assets—at runtime (see [`docs/CONFIG_AND_SECRETS.md`](CONFIG_AND_SECRETS.md)). Core apps and packages must remain completely white-label.
- **Bring Your Own API Keys (BYOK)**: Third-party integrations and optional features are powered by the operator's own backend-stored API keys, never hardcoded, committed, or shipped in client binaries.
- **Self-Hosted (Bring Your Own Hosting)**: The platform is designed to be deployed and operated on the user's own hosting and infrastructure, with no lock-in to a single cloud vendor or managed service.

## Strict Brand-Agnostic Rule

- **Zero fixed brands or external project references**: No files in this repository (code, tests, docs, comments, agent prompts, or commit messages) may mention any fixed venue brand or any external private/test project.
- **Zero hardcoded URLs or brand strings in `lib/`**: All server endpoints, branding values, and keys enter through runtime/build configuration (`ClientEndpointConfig`, `VenueBootstrap`, backend config/vault).
- **Generic placeholders only in docs/tests**: Use neutral placeholders like `Example Venue` and `example.com` when illustrating tests or documentation.

## Implications for Agents & Contributors

- Keep venue branding, copy, and visual assets configurable/overridable across all apps and packages.
- Externalize all third-party service credentials on the backend (`IntegrationKeyStatus` for UI status only), with safe gating (`VenueCapabilities`) when a key is omitted.
- Avoid coupling deployment scripts, networking, or storage assumptions to a single proprietary host; keep infrastructure portable (standard containers, configurable URLs, and storage paths).
