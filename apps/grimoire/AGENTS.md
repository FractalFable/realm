# apps/grimoire

- **Purpose**: Multi-platform (Web-first, expanding to macOS/Windows/mobile) E2EE interactive notes client shell.
- **Allowed deps**: `flutter_bloc`, `material_ui`, `realm_core`, `realm_ui`, `realm_a2ui`, `grimoire_core`, `grimoire_notes` (zero `tavern_*`).
- **Public API**: `lib/src/app.dart` (`GrimoireApp`) and `lib/main.dart`.
- **Commands**: `(cd apps/grimoire && flutter test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: Thin shell only (business logic lives in `grimoire_notes` / `grimoire_core`); `kDebugMode`-only `ext.realm.getState` exposes zero secrets/PII; zero hardcoded `http(s)://` URLs or fixed brands in `lib/`; `ValueKey` + `Semantics` on controls.
- **Tier**: Tier 2–3 (`apps/grimoire/**`).
