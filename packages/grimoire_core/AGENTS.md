# packages/grimoire_core

- **Purpose**: Pure-Dart interactive note AST, link graph, local vault/RAG/script runtime contracts, and encrypted sync envelope DTOs for Grimoire.
- **Allowed deps**: `meta`, `realm_core` only (no Flutter, no `dart:io`, no HTTP, no `tavern_*`).
- **Public API**: `lib/grimoire_core.dart` (`NoteBlock`, `NoteDocument`, `NoteGraph`, `EncryptedBlobEnvelope`, `CipherSuite`, `LocalVaultStore`, `InMemoryVaultStore`, `LocalNoteSearchIndex`, `AiTrustTier`, `ScriptRuntime`, `SandboxedScriptRuntime`).
- **Commands**: `(cd packages/grimoire_core && dart test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: `WebEmbedBlock` allows `https://` only with no userinfo; `NoteDocument` enforces unique block IDs; `optInByokCloud` search strictly excludes `excludeFromCloudAi` notes; zero hardcoded `http(s)://` URLs in `lib/`.
- **Tier**: Tier 3 (`packages/grimoire_core/**`; shared client/server sync DTOs and domain invariants).
