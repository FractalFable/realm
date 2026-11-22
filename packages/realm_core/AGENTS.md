# packages/realm_core

- **Purpose**: App-neutral pure-Dart endpoint, branding, bootstrap, and BYOK status contracts.
- **Allowed deps**: `meta` only (no Flutter, no `dart:io`, no HTTP, no app-specific packages).
- **Public API**: `lib/realm_core.dart` (`AppBranding`, `AppConfig`, `AppBootstrap`, `AppCapabilities`, `HostingMode`, `ClientEndpointConfig`, `IntegrationKeyStatus`, plus `Venue*` compat types).
- **Commands**: `(cd packages/realm_core && dart test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: No hardcoded `http(s)://` URLs or fixed venue brands; all fields validated at construction and JSON decode; `IntegrationKeyStatus` never holds raw secrets.
- **Tier**: Tier 3 (`packages/realm_core/**`).
