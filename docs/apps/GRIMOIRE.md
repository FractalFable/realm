# Grimoire Architecture

*Status: Accepted direction (2026-11-22).*

**Grimoire** is Realm's multi-platform (starting **Web-first**, expanding next to **macOS and Windows**, with iOS/Android later), end-to-end encrypted (E2EE), interactive note-taking application. Notes are structured, linkable, scriptable, embed-capable, and powered by local-first RAG and A2UI. All `packages/*` remain platform-neutral behind `LocalVaultStore` and `ScriptRuntime` interfaces, using Realm's **modern-fantasy UI** (`realm_ui`, dynamically seeded from `AppBranding`) and **pure-Dart shared DTOs** (`grimoire_core` / `grimoire_protocol`) with zero code generation.

## Packages & Apps

- `packages/grimoire_core` — Pure-Dart note domain models (`NoteDocument`, sealed `NoteBlock` AST, `NoteGraph` backlinks/GraphRAG traversal, `EncryptedBlobEnvelope`). Zero `dart:io` or Flutter dependencies so it runs identically on Web, mobile, desktop, and server.
- `packages/realm_crypto` (**Tier 4**, app-neutral) — Pure-Dart client-side E2EE primitives (`XChaCha20-Poly1305` / `AES-256-GCM` AEAD with canonical AAD binding, HKDF-SHA256 subkeys, Argon2id master-key derivation).
- `packages/realm_a2ui` (app-neutral) — Declarative A2UI surface renderer (`a2ui_core` + `a2ui_flutter`) shared with Tavern.
- `apps/grimoire` — Multi-platform Flutter client (iOS, Android, macOS, Web). Local-first encrypted storage, client-side RAG, sandboxed script runner, and A2UI workspace.
- `apps/grimoire_server` — Zero-knowledge Relic 2 encrypted blob & revision sync server built on `realm_server_kit` and `realm_auth`. Stores only authenticated ciphertext envelopes and never receives plaintext notes, titles, tags, or vault keys.

## 1. Interactive Block & Link Model (Not Plain Markdown)

Every `NoteDocument` holds an ordered list of typed `NoteBlock`s (`grimoire_core`):
- `RichTextBlock` — Headings, paragraphs, quotes, checklists, and code blocks.
- `NoteLinkBlock` — First-class bi-directional note/block links, indexed by `NoteGraph` for instant backlinks and multi-hop graph traversal.
- `WebEmbedBlock` — Sandboxed website embed (`https://`-only URI, explicit `allowInteractive` opt-in, domain allowlist + fallback preview card, zero access to vault keys or script bridges).
- `ScriptBlock` — Inline runnable script with explicit per-block capability grants.
- `A2uiBlock` — Persistent or live agent-generated declarative UI surface rendered via `realm_a2ui`.

## 2. End-to-End Encryption (Tier 4)

- **Key Hierarchy**: Client derives a Vault Master Key locally from user passphrase/passkey + recovery key using Argon2id + HKDF-SHA256. Per-note/per-blob Data Encryption Keys (DEKs) are wrapped locally.
- **Authenticated Encryption**: Every synced note, attachment, and search index chunk is encrypted client-side with `XChaCha20-Poly1305` or `AES-256-GCM` via `realm_crypto` and bound via canonical AAD `(vault_id, blob_id, revision, key_version, cipher_suite)` to prevent cross-vault, cross-note, or rollback tampering.
- **Zero-Knowledge Server**: `apps/grimoire_server` stores only `EncryptedBlobEnvelope` ciphertext and opaque revision metadata.

## 3. Local-First Hybrid RAG + A2UI

Because the server cannot read E2EE notes, **indexing and retrieval run client-side**:
- **Hybrid Index**: Local encrypted FTS5 full-text index + local vector embeddings + `NoteGraph` backlinks (GraphRAG pulls linked context alongside semantic matches). Encrypted vector index shards sync via `grimoire_server` so mobile devices reuse desktop-computed embeddings without leaking plaintext.
- **Explicit AI Trust Tiers** (user-configurable):
  1. **Strict Private / Local AI (100% E2EE)**: On-device or user self-hosted LAN/VPS LLM (e.g., Ollama / vLLM). Plaintext never leaves user-controlled hardware.
  2. **Opt-In BYOK Cloud AI (Zero-Knowledge at Rest)**: Client runs RAG locally, strips notes marked `excludeFromCloudAi`, and sends only minimal retrieved snippets + tool declarations to the user's BYOK LLM (via zero-retention endpoints where available).
- **A2UI Output**: The agent calls client-side retrieval tools (`searchNotes`, `getLinkedNotes`, etc.) and streams declarative **A2UI JSON** rendered natively through `realm_a2ui` in `apps/grimoire` ([A2UI Note](../A2UI.md)).

## 4. Cross-Platform Sandboxed Scripting (iOS, Android, macOS, Web)

To support inline scripts everywhere—including **iOS App Store** rules prohibiting unsigned JIT downloads—Grimoire uses **sandboxed ES2023 JavaScript** behind a unified `ScriptRuntime` interface:
- **Native (iOS, Android, macOS)**: Embedded **QuickJS** interpreter (no JIT) with strict CPU timeout and memory cap.
- **Web**: Isolated **Web Worker** with no DOM, cookie, or localStorage access.
- **Capability Permissions**: Every `ScriptBlock` declares required permissions (`readCurrentNote`, `queryNotes`, `network`, `emitA2ui`), gated by explicit user approval before execution.
- **Native UI Output**: Scripts can return plain values, structured data, or **A2UI JSON** rendered natively with `realm_ui` themes. AI assistants may draft or edit `ScriptBlock`s, always subject to user review before running.
