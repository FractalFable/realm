# packages/tavern_core

- **Purpose**: Pure-Dart pub and restaurant domain primitives for Tavern.
- **Allowed deps**: `meta`, `realm_core` only (no Flutter, no `dart:io`, no HTTP, no `grimoire_*`).
- **Public API**: `lib/tavern_core.dart` (`Money`, `LocalizedText`, `TableCode`, re-exported `Venue*` and `HostingMode`).
- **Commands**: `(cd packages/tavern_core && dart test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: All money arithmetic uses integer minor units (`Money.minorUnits`); table codes are unguessable (`>= 12` URL-safe chars); zero fixed venue brands.
- **Tier**: Tier 3 (`packages/tavern_core/**`; money types require careful validation).
