# packages/realm_protocol

- **Purpose**: App-neutral pure-Dart wire contracts (`Endpoint`, `ApiError`, `Result`, `LiveEvent`).
- **Allowed deps**: `meta`, `realm_core` only (never Flutter, `dart:io`, HTTP, codegen, `tavern_*`, or `grimoire_*`).
- **Public API**: `lib/realm_protocol.dart` (`HttpMethod`, `ApiErrorCode`, `ApiError`, `Result`, `Ok`, `Err`, `ApiResult`, `EmptyPayload`, `Endpoint`, `LiveEvent`).
- **Commands**: `(cd packages/realm_protocol && dart test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: No codegen; strict enum decoding; zero hardcoded `http(s)://` URLs in `lib/`.
- **Tier**: Tier 3 (`packages/realm_protocol/**`; shared client/server wire contracts).
