# apps/grimoire_server

- **Purpose**: Zero-knowledge Grimoire sync server built on `realm_server_kit` and `grimoire_core`.
- **Allowed deps**: `grimoire_core`, `realm_core`, `realm_server_kit`, `relic` (never Flutter, never `tavern_*`).
- **Public API**: `lib/grimoire_server.dart` (`createGrimoireServerApp`) and `bin/grimoire_server.dart`.
- **Commands**: `(cd apps/grimoire_server && dart test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: Zero-knowledge storage (only ciphertext envelopes, never plaintext notes/keys); zero hardcoded `http(s)://` URLs in `lib/`.
- **Tier**: Tier 3 minimum (`apps/*_server/**`); Tier 4 for `auth/`, `migrations/`.
