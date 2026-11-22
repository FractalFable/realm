# packages/realm_server_kit

- **Purpose**: App-neutral Relic 2 server helpers (`/health`, `/api/v1/bootstrap`, JSON responses).
- **Allowed deps**: `meta`, `realm_core`, `relic` only (never Flutter, never `tavern_*` or `grimoire_*`).
- **Public API**: `lib/realm_server_kit.dart` (`RealmServerSpec`, `createRealmApp`, `jsonOk`, `jsonError`).
- **Commands**: `(cd packages/realm_server_kit && dart test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: App-neutral; zero secrets in `/api/v1/bootstrap`; zero hardcoded `http(s)://` URLs in `lib/`.
- **Tier**: Tier 3 (`packages/realm_server_kit/**`).
