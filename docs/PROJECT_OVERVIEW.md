# Project Overview

**Realm** is an open-source pub and restaurant management platform. Each operator/venue runs their own instance and retains full control over branding, integrations, and infrastructure.

## Core Principles

- **Bring Your Own Branding (White-Label)**: Operators supply their own venue branding—name, logos, colors, themes, domain, and copy/assets. Core apps and packages must treat branding as configuration rather than hardcoding venue-specific identity.
- **Bring Your Own API Keys (BYOK)**: Third-party integrations and optional features are powered by the operator's own API keys supplied via environment variables or runtime configuration—never hardcoded or committed to source control.
- **Self-Hosted (Bring Your Own Hosting)**: The platform is designed to be deployed and operated on the user's own hosting and infrastructure, with no lock-in to a specific cloud vendor or managed service.

## Implications for Agents & Contributors

- Keep venue branding, copy, and visual assets configurable/overridable across all apps and packages.
- Externalize all third-party service credentials and API keys behind documented env vars or config schemas, with safe fallbacks/feature gating when a key is omitted.
- Avoid coupling deployment scripts, networking, or storage assumptions to a single proprietary host; keep infrastructure portable (e.g., standard containers/Docker, configurable base URLs and storage paths).
