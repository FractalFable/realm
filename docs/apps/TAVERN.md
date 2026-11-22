# Tavern Architecture

*Status: Accepted direction (2026-11-22).*

**Tavern** is Realm's standalone, white-label pub and restaurant management suite, built on the shared Realm platform (`realm_core`, `realm_ui`, `realm_a2ui`, `realm_server`).

## Packages & Apps

- `packages/tavern_core` — Pure-Dart pub/restaurant domain primitives (re-exports `VenueBranding`, `VenueConfig`, `VenueCapabilities`, `VenueBootstrap`, `HostingMode` alongside `Money` integer minor units, `LocalizedText` for `en`/`sl`, and unguessable `TableCode`).
- `apps/tavern_staff` — Responsive Flutter web app for venue staff and managers (live order board, order status updates, menu management, venue branding & BYOK settings, optional A2UI staff copilot).
- `apps/tavern_guest` — Responsive Flutter web app for guests (QR `/t/<table-code>` menu, cart, order placement, live WebSocket order status, optional A2UI menu/pairing discovery).
- `apps/realm_server` (`tavern` module) — Relic 2 API, PostgreSQL persistence, WebSocket live updates, Besteron/in-person payment tracking, and BYOK LLM proxy.

## Inherited Platform Rules

- **Deployment, Hosting, State & Routing**: Follows [Architecture Decisions](../ARCHITECTURE.md) §2–§12 (Relic 2, Postgres 16 + numbered migrations, `realm_protocol`, `flutter_bloc` Cubits, `go_router` + `go_router_builder`, one venue per instance, Caddy reverse proxy).
- **Staff Accounts, Payments, Tables & Languages**: All operator decisions in [Architecture Decisions](../ARCHITECTURE.md) §12 apply directly to Tavern (`en`/`sl` localization, Argon2id staff accounts, server-authoritative order totals, Besteron webhook verification + `payment_events` append-only ledger).
- **Generative UI (A2UI)**: Uses optional `realm_a2ui` ([A2UI Note](../A2UI.md)). A2UI surfaces are presentation + typed intents only; pricing, inventory, allergen integrity, authorization, and payments are enforced server-side and pass Tier 4 review ([Review Policy](../REVIEW_POLICY.md)).
- **White-Label & BYOK**: Zero hardcoded venue brands or `http(s)://` URLs in `lib/`. All secrets stay server-side ([Config & Secrets](../CONFIG_AND_SECRETS.md)).
