import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

/// Supported AEAD cipher suites in `realm_crypto`.
enum RealmCipherSuite {
  /// Primary cross-platform AEAD: 256-bit key, 192-bit (24-byte) nonce, 16-byte MAC.
  xchacha20Poly1305(nonceLength: 24, macLength: 16),

  /// AES-256-GCM: 256-bit key, 96-bit (12-byte) nonce, 16-byte MAC.
  aes256Gcm(nonceLength: 12, macLength: 16);

  const RealmCipherSuite({required this.nonceLength, required this.macLength});

  /// Parses a [RealmCipherSuite] from its enum [name].
  static RealmCipherSuite fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw const RealmCryptoException('Unknown cipher suite.');
  }

  /// Required nonce length in bytes for this suite.
  final int nonceLength;

  /// Required authentication tag length in bytes for this suite.
  final int macLength;
}

/// Typed exception thrown on cryptographic validation or authentication errors.
///
/// Never includes secret key material or plaintext in [message].
@immutable
class RealmCryptoException implements Exception {
  /// Creates a [RealmCryptoException] with a non-secret [message].
  const RealmCryptoException(this.message);

  /// Safe, non-secret diagnostic message.
  final String message;

  @override
  String toString() => 'RealmCryptoException: $message';
}

/// Canonical length-prefixed UTF-8 AAD encoder preventing boundary ambiguity
/// across metadata fields (e.g. `['ab', 'c']` vs `['a', 'bc']`).
Uint8List encodeCanonicalAad(List<String> fields) {
  final builder = BytesBuilder(copy: false);
  final header = ByteData(4)..setUint32(0, fields.length);
  builder.add(header.buffer.asUint8List());
  for (final field in fields) {
    final encoded = utf8.encode(field);
    final lengthBytes = ByteData(4)..setUint32(0, encoded.length);
    builder
      ..add(lengthBytes.buffer.asUint8List())
      ..add(encoded);
  }
  return builder.takeBytes();
}

/// Authenticated encrypted payload containing suite, nonce, ciphertext, and MAC.
@immutable
class SealedPayload._({
  required final RealmCipherSuite cipherSuite,
  required final Uint8List nonce,
  required final Uint8List ciphertext,
  required final Uint8List mac,
}) {
  /// Creates and validates a [SealedPayload], copying byte buffers defensively.
  factory SealedPayload({
    required RealmCipherSuite cipherSuite,
    required List<int> nonce,
    required List<int> ciphertext,
    required List<int> mac,
  }) {
    if (nonce.length != cipherSuite.nonceLength) {
      throw RealmCryptoException(
        'Invalid nonce length ${nonce.length} for ${cipherSuite.name}; '
        'expected ${cipherSuite.nonceLength} bytes.',
      );
    }
    if (mac.length != cipherSuite.macLength) {
      throw RealmCryptoException(
        'Invalid MAC length ${mac.length} for ${cipherSuite.name}; '
        'expected ${cipherSuite.macLength} bytes.',
      );
    }
    return SealedPayload._(
      cipherSuite: cipherSuite,
      nonce: Uint8List.fromList(nonce),
      ciphertext: Uint8List.fromList(ciphertext),
      mac: Uint8List.fromList(mac),
    );
  }

  /// Parses a [SealedPayload] from a combined `[ciphertext || mac]` buffer and
  /// explicit [nonce].
  factory SealedPayload.fromCiphertextAndMac({
    required RealmCipherSuite cipherSuite,
    required List<int> nonce,
    required List<int> combinedCiphertextAndMac,
  }) {
    if (combinedCiphertextAndMac.length < cipherSuite.macLength) {
      throw RealmCryptoException(
        'Ciphertext buffer shorter than ${cipherSuite.macLength}-byte MAC.',
      );
    }
    final splitAt = combinedCiphertextAndMac.length - cipherSuite.macLength;
    return SealedPayload(
      cipherSuite: cipherSuite,
      nonce: nonce,
      ciphertext: combinedCiphertextAndMac.sublist(0, splitAt),
      mac: combinedCiphertextAndMac.sublist(splitAt),
    );
  }

  /// Encodes `[ciphertext || mac]` as Base64 for transport envelopes.
  String get ciphertextAndMacBase64 => base64Encode([...ciphertext, ...mac]);

  /// Encodes [nonce] as Base64 for transport envelopes.
  String get nonceBase64 => base64Encode(nonce);
}

/// Pure-Dart authenticated encryption (AEAD) supporting XChaCha20-Poly1305 and
/// AES-256-GCM with mandatory key/nonce validation and AAD binding.
class RealmAeadCipher {
  /// Creates a [RealmAeadCipher] instance.
  const RealmAeadCipher();

  /// Required symmetric key length in bytes (256-bit).
  static const int keyLengthBytes = 32;

  static final Cipher _xchacha = Xchacha20.poly1305Aead();
  static final Cipher _aesGcm = AesGcm.with256bits();

  Cipher _cipherFor(RealmCipherSuite suite) => switch (suite) {
    RealmCipherSuite.xchacha20Poly1305 => _xchacha,
    RealmCipherSuite.aes256Gcm => _aesGcm,
  };

  /// Encrypts [plaintext] under 32-byte [keyBytes] with a fresh CSPRNG nonce
  /// and canonical [aad] binding.
  Future<SealedPayload> encrypt({
    required RealmCipherSuite suite,
    required List<int> keyBytes,
    required List<int> plaintext,
    required List<int> aad,
  }) async {
    if (keyBytes.length != keyLengthBytes) {
      throw RealmCryptoException(
        'Invalid AEAD key length ${keyBytes.length}; expected $keyLengthBytes bytes.',
      );
    }
    if (aad.isEmpty) {
      throw const RealmCryptoException(
        'Associated data (AAD) must not be empty.',
      );
    }

    final cipher = _cipherFor(suite);
    final secretKey = SecretKeyData(
      Uint8List.fromList(keyBytes),
      overwriteWhenDestroyed: true,
    );
    try {
      final nonce = cipher.newNonce();
      if (nonce.length != suite.nonceLength) {
        throw const RealmCryptoException('Generated nonce length mismatch.');
      }
      final box = await cipher.encrypt(
        plaintext,
        secretKey: secretKey,
        nonce: nonce,
        aad: aad,
      );
      return SealedPayload(
        cipherSuite: suite,
        nonce: box.nonce,
        ciphertext: box.cipherText,
        mac: box.mac.bytes,
      );
    } finally {
      secretKey.destroy();
    }
  }

  /// Decrypts and authenticates [payload] under 32-byte [keyBytes] and [aad].
  ///
  /// Throws [RealmCryptoException] if the key, nonce, ciphertext, MAC, or AAD
  /// does not authenticate.
  Future<Uint8List> decrypt({
    required SealedPayload payload,
    required List<int> keyBytes,
    required List<int> aad,
  }) async {
    if (keyBytes.length != keyLengthBytes) {
      throw RealmCryptoException(
        'Invalid AEAD key length ${keyBytes.length}; expected $keyLengthBytes bytes.',
      );
    }
    if (aad.isEmpty) {
      throw const RealmCryptoException(
        'Associated data (AAD) must not be empty.',
      );
    }
    if (payload.nonce.length != payload.cipherSuite.nonceLength) {
      throw const RealmCryptoException('Invalid payload nonce length.');
    }
    if (payload.mac.length != payload.cipherSuite.macLength) {
      throw const RealmCryptoException('Invalid payload MAC length.');
    }

    final cipher = _cipherFor(payload.cipherSuite);
    final secretKey = SecretKeyData(
      Uint8List.fromList(keyBytes),
      overwriteWhenDestroyed: true,
    );
    List<int>? clearBytes;
    try {
      final box = SecretBox(
        payload.ciphertext,
        nonce: payload.nonce,
        mac: Mac(payload.mac),
      );
      clearBytes = await cipher.decrypt(box, secretKey: secretKey, aad: aad);
      return Uint8List.fromList(clearBytes);
    } on SecretBoxAuthenticationError {
      throw const RealmCryptoException(
        'AEAD authentication failed (wrong key, tampered data, or AAD mismatch).',
      );
    } finally {
      if (clearBytes case final Uint8List bytes) {
        bytes.fillRange(0, bytes.length, 0);
      }
      secretKey.destroy();
    }
  }
}
