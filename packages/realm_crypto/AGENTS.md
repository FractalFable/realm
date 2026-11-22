# packages/realm_crypto

- **Purpose**: App-neutral client-side AEAD encryption (`XChaCha20-Poly1305`, `AES-256-GCM`) and KDF (`Argon2id`, `HKDF-SHA256`).
- **Allowed deps**: `cryptography`, `meta` only (never Flutter, never `dart:io`, never `tavern_*` or `grimoire_*`).
- **Public API**: `lib/realm_crypto.dart` (`RealmCipherSuite`, `SealedPayload`, `RealmAeadCipher`, `encodeCanonicalAad`, `RealmKeyDerivation`, `RealmCryptoException`).
- **Commands**: `(cd packages/realm_crypto && dart test --reporter=failures-only)` and `./scripts/check.sh --quiet`.
- **Invariants**: All crypto lives under `lib/src/crypto/`; mandatory fresh random nonces and canonical length-prefixed AAD binding; zero secret/key logging.
- **Tier**: **Tier 4 (Critical)** — requires `security-auditor`, `critic`, and human sign-off (`NEEDS HUMAN SIGN-OFF`).
