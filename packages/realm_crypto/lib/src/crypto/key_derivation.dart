import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

import 'aead_cipher.dart';

/// Argon2id cost parameters for client-side E2EE master key derivation.
@immutable
class const Argon2idParameters._({
  required final int memoryKiB,
  required final int iterations,
  required final int parallelism,
  final int hashLength = 32,
}) {
  /// Creates and validates [Argon2idParameters].
  factory Argon2idParameters({
    required int memoryKiB,
    required int iterations,
    required int parallelism,
    int hashLength = 32,
  }) {
    if (parallelism < 1) {
      throw const RealmCryptoException('Argon2id parallelism must be >= 1.');
    }
    if (iterations < 1) {
      throw const RealmCryptoException('Argon2id iterations must be >= 1.');
    }
    if (memoryKiB < 4 * parallelism || memoryKiB % (4 * parallelism) != 0) {
      throw const RealmCryptoException(
        'Argon2id memoryKiB must be >= 4 * parallelism and divisible by 4 * parallelism.',
      );
    }
    if (hashLength < 16) {
      throw const RealmCryptoException(
        'Argon2id hashLength must be >= 16 bytes.',
      );
    }
    return Argon2idParameters._(
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: hashLength,
    );
  }

  /// OWASP-aligned interactive E2EE baseline (19 MiB, 2 iterations, 1 lane,
  /// 32-byte key), audited for cross-platform Dart & Web performance.
  static const Argon2idParameters owaspBaseline = Argon2idParameters._(
    memoryKiB: 19456,
    iterations: 2,
    parallelism: 1,
  );
}

/// Pure-Dart key derivation helpers (Argon2id + HKDF-SHA256) with explicit
/// domain separation and defensive secret buffer wiping.
class RealmKeyDerivation {
  /// Creates a [RealmKeyDerivation] instance.
  const RealmKeyDerivation();

  /// Minimum required random salt length in bytes.
  static const int minSaltLengthBytes = 16;

  /// Generates [length] cryptographically secure random bytes.
  static Uint8List randomBytes([int length = minSaltLengthBytes]) {
    if (length < 1) {
      throw const RealmCryptoException('Random byte length must be >= 1.');
    }
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256), growable: false),
    );
  }

  /// Derives a master key from [passphrase] and [salt] using Argon2id.
  ///
  /// Defaults to [Argon2idParameters.owaspBaseline]. Always store [parameters]
  /// and [salt] alongside vault metadata for forward compatibility.
  Future<Uint8List> deriveMasterKeyArgon2id({
    required String passphrase,
    required List<int> salt,
    Argon2idParameters parameters = Argon2idParameters.owaspBaseline,
  }) async {
    if (passphrase.isEmpty) {
      throw const RealmCryptoException('Passphrase must not be empty.');
    }
    if (salt.length < minSaltLengthBytes) {
      throw const RealmCryptoException(
        'Argon2id salt must be at least $minSaltLengthBytes bytes.',
      );
    }

    final passBytes = Uint8List.fromList(utf8.encode(passphrase));
    final secretKey = SecretKeyData(passBytes, overwriteWhenDestroyed: true);
    try {
      final argon2id = Argon2id(
        parallelism: parameters.parallelism,
        memory: parameters.memoryKiB,
        iterations: parameters.iterations,
        hashLength: parameters.hashLength,
      );
      final derived = await argon2id.deriveKey(
        secretKey: secretKey,
        nonce: salt,
      );
      final rawBytes = await derived.extractBytes();
      final out = Uint8List.fromList(rawBytes);
      if (rawBytes is Uint8List) {
        rawBytes.fillRange(0, rawBytes.length, 0);
      }
      derived.destroy();
      return out;
    } finally {
      secretKey.destroy();
    }
  }

  /// Derives a domain-separated subkey using HKDF-SHA256.
  Future<Uint8List> deriveSubkeyHkdfSha256({
    required List<int> inputKeyBytes,
    required String info,
    List<int> salt = const [],
    int outputLength = RealmAeadCipher.keyLengthBytes,
  }) async {
    if (inputKeyBytes.length < 16) {
      throw const RealmCryptoException(
        'HKDF inputKeyBytes must be at least 16 bytes.',
      );
    }
    if (info.trim().isEmpty) {
      throw const RealmCryptoException(
        'HKDF info domain separation label must not be empty.',
      );
    }
    if (outputLength < 16 || outputLength > 255 * 32) {
      throw const RealmCryptoException(
        'HKDF outputLength must be between 16 and 8160 bytes.',
      );
    }

    final inputKey = SecretKeyData(
      Uint8List.fromList(inputKeyBytes),
      overwriteWhenDestroyed: true,
    );
    try {
      final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: outputLength);
      final derived = await hkdf.deriveKey(
        secretKey: inputKey,
        nonce: salt,
        info: utf8.encode(info),
      );
      final out = Uint8List.fromList(derived.bytes);
      derived.destroy();
      return out;
    } finally {
      inputKey.destroy();
    }
  }
}
