# packages/realm_a2ui

- **Purpose**: App-neutral A2UI surface host wrapping `a2ui_core` and `a2ui_flutter`.
- **Allowed deps**: `flutter`, `material_ui`, `realm_core`, `realm_ui`, `a2ui_core`, `a2ui_flutter` (never `tavern_*` or `grimoire_*`).
- **Public API**: `lib/realm_a2ui.dart` (`RealmA2uiHost`).
- **Commands**: `(cd packages/realm_a2ui && flutter test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: App-neutral; AI features gracefully gated when disabled; inherits `Theme.of(context)`; zero hardcoded `http(s)://` URLs in `lib/`.
- **Tier**: Tier 3 (`packages/realm_a2ui/**`).
