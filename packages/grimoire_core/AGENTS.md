# packages/grimoire_core

- **Purpose**: Pure-Dart interactive note AST, link graph, and encrypted sync envelope contracts for Grimoire.
- **Allowed deps**: `meta`, `realm_core` only (no Flutter, no `dart:io`, no HTTP, no `tavern_*`).
- **Public API**: `lib/grimoire_core.dart` (`NoteBlock` sealed hierarchy, `NoteDocument`, `NoteGraph`, `EncryptedBlobEnvelope`, `CipherSuite`).
- **Commands**: `(cd packages/grimoire_core && dart test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: `WebEmbedBlock` allows `https://` only with no userinfo; `NoteDocument` enforces unique block IDs; zero hardcoded `http(s)://` URLs in `lib/`.
- **Tier**: Tier 3 (`packages/grimoire_core/**`; shared client/server sync DTOs and domain invariants).
