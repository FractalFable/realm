# Config, Branding & BYOK Secrets

Realm separates client endpoints, runtime branding, and backend secrets into **three layers** so operators deploy one shared codebase with zero code edits or rebuilds per venue.

## 1. Client-to-Server Entry Point (`ClientEndpointConfig`)

Client apps must never hardcode server URLs or venue domains in `lib/` code. Resolve the backend URL using [`ClientEndpointConfig.resolve`](../packages/realm_core/lib/src/client_endpoint_config.dart) in precedence order:
1. **Explicit override** (one-time tablet/staff QR onboarding or CLI override):
   - [`ClientEndpointConfig`](../packages/realm_core/lib/src/client_endpoint_config.dart) enforces HTTPS outside local loopback (`localhost`, `127.0.0.1`, `::1`) by default; isolated LAN deployments must pass `allowInsecureHttp: true` explicitly.
   - QR endpoint overrides must display the target domain and require explicit operator confirmation before saving.
2. **Runtime / build config JSON** (`{"apiBaseUrl": "https://..."}`):
   - **Web**: mounted `/config.json` served alongside the web bundle.
   - **Mobile / Desktop**: `--dart-define-from-file=venue.json` (`venue.json`, `**/venue.json`, and `config.local.json` are gitignored).
3. **Web same-origin fallback** (`Uri.parse(Uri.base.origin)` when UI and API share a domain behind a reverse proxy).

Use [`ClientEndpointConfig.endpoint`](../packages/realm_core/lib/src/client_endpoint_config.dart) to join relative API paths safely while preserving base path prefixes and rejecting traversal or scheme overrides.

## 2. Runtime Bootstrap (`GET /api/v1/bootstrap`)

Rather than baking venue names, colors, logos, or feature toggles into builds, clients fetch [`VenueBootstrap`](../packages/realm_core/lib/src/venue_bootstrap.dart) from the backend at startup:
- **`VenueBranding`**: operator name, `primaryColorArgb`, optional `tagline` and `logoUrl` (applied directly via `realm_ui` theming).
- **`VenueCapabilities`**: strictly public, non-secret booleans (`aiAssistantEnabled`, `onlineOrderingEnabled`, `paymentsEnabled`) computed server-side from configured BYOK keys so clients gracefully enable or hide optional modules. *(Note: `IntegrationKeyStatus` covers additional backend-only providers like `posFiscal`, `email`, and `sms`; never expose `IntegrationKeyStatus` on `/api/v1/bootstrap`.)*
- **`HostingMode`**: `.selfHosted` or `.managed`.

## 3. Server-Only Secrets & BYOK API Keys

- **Never ship API keys in Flutter clients.** All LLM, payment, POS/fiscal, email, and SMS calls proxy through the Dart backend.
- **Infrastructure secrets** (database credentials, JWT signing keys, `REALM_MASTER_KEY`):
  - *Local dev*: gitignored `.env` paired with a committed `.env.example` containing placeholder keys only.
  - *Staging / Production*: **Docker Secrets** (`/run/secrets/*` or `*_FILE` env pointers), `systemd` `LoadCredential`, or **SOPS + `age`** encrypted files—avoid plaintext `.env` files on production hosts.
  - **Key separation**: `REALM_MASTER_KEY` (KEK) must be strictly separate from JWT signing secrets and database passwords.
- **Envelope Encryption for Stored BYOK Keys**:
  - Store operator BYOK credentials in Postgres using **versioned envelope encryption** (`kek_version`, `key_id`, `encrypted_dek`, `dek_nonce`, `ciphertext`, `ciphertext_nonce`, or self-contained nonce-prefixed AEAD blobs) with an authenticated AEAD cipher (**AES-256-GCM** or **XChaCha20-Poly1305**), unique random nonces per encryption, and **AAD binding** `(venue_id, provider, key_version)` to prevent cross-tenant or cross-provider ciphertext swapping.
  - Retain previous KEK versions in the server key ring during `REALM_MASTER_KEY` rotation until all rows are re-encrypted.
  - Support future environment tagging (e.g., `sandbox` vs. `live` credentials) per provider where applicable.
- **Precedence, Rotation & Access Control**:
  - **Resolution precedence**: Secret file (`*_FILE` / `/run/secrets/*`) → environment variable → `encryptedVault` (Postgres). When overridden by file or env var, lock Admin UI writes for that provider with `409 Conflict` so operators are not misled by stale DB edits.
  - **Dual-secret rotation overlap**: Support overlapping active + previous webhook/signing credentials for `payments` and `posFiscal` during zero-downtime key rotation.
  - **RBAC, Transport & Audit**: Admin-only RBAC over TLS-only endpoints, append-only audit logs on key create/rotate/revoke (never logging secret values), and server-side masked `keyHint` generation only for secrets of `>= 16` characters (never accepting client-supplied hints, returning only [`IntegrationKeyStatus`](../packages/realm_core/lib/src/integration_key_status.dart)).
