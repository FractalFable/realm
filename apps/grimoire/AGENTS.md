# apps/grimoire

- **Purpose**: Multi-platform (iOS, Android, macOS, Web) E2EE interactive notes client.
- **Allowed deps**: `material_ui`, `realm_core`, `realm_ui`, `realm_a2ui`, `grimoire_core` (zero `tavern_*`).
- **Public API**: `lib/src/app.dart` (`GrimoireApp`) and `lib/main.dart`.
- **Commands**: `(cd apps/grimoire && flutter test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: E2EE client-first trust boundary; zero hardcoded `http(s)://` URLs or fixed brands in `lib/`; `ValueKey` + `Semantics` on controls.
- **Tier**: Tier 2–3 (`apps/grimoire/**`).
