# apps/tavern_guest

- **Purpose**: Responsive Flutter web shell for Tavern guest ordering and discovery.
- **Allowed deps**: `material_ui`, `realm_core`, `realm_ui`, `tavern_core` (zero `dart:io`, zero `grimoire_*`).
- **Public API**: `lib/src/app.dart` (`TavernGuestApp`) and `lib/main.dart`.
- **Commands**: `(cd apps/tavern_guest && flutter test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: Web-compatible; zero hardcoded venue brands or `http(s)://` URLs in `lib/`; `ValueKey` + `Semantics` on controls.
- **Tier**: Tier 2–3 (`apps/tavern_guest/**`).
