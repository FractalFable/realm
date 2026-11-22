# apps/tavern_server

- **Purpose**: Tavern backend server built on `realm_server_kit` and `tavern_core`.
- **Allowed deps**: `realm_core`, `realm_server_kit`, `tavern_core`, `relic` (never Flutter, never `grimoire_*`).
- **Public API**: `lib/tavern_server.dart` (`createTavernServerApp`) and `bin/tavern_server.dart`.
- **Commands**: `(cd apps/tavern_server && dart test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: Server-authoritative prices/totals; zero BYOK secrets in bootstrap; zero hardcoded `http(s)://` URLs in `lib/`.
- **Tier**: Tier 3 minimum (`apps/*_server/**`); Tier 4 for `auth/`, `payments/`, `integrations/`, `migrations/`.
