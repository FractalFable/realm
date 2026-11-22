import 'dart:convert';

import 'package:meta/meta.dart';

/// Supported AEAD cipher suites for client-side E2EE Grimoire sync blobs.
enum CipherSuite {
  xchacha20Poly1305,
  aes256Gcm;

  /// Parses a [CipherSuite] from its JSON [name].
  static CipherSuite fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError.value(name, 'cipherSuite', 'Unknown CipherSuite.');
  }
}

void _requireValidNonEmptyBase64(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, '$name must not be empty.');
  }
  try {
    final decoded = base64Decode(value);
    if (decoded.isEmpty) {
      throw ArgumentError.value(
        value,
        name,
        '$name must decode to non-empty bytes.',
      );
    }
  } on FormatException catch (e) {
    throw ArgumentError.value(value, name, 'Invalid Base64 for $name: $e');
  }
}

DateTime _parseUtcIso(Object? raw, String name) {
  if (raw is! String || !_isoTzPattern.hasMatch(raw)) {
    throw ArgumentError.value(
      raw,
      name,
      'Expected an ISO-8601 timestamp string with explicit timezone.',
    );
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw ArgumentError.value(raw, name, 'Invalid ISO-8601 timestamp.');
  }
  return parsed.toUtc();
}

final RegExp _isoTzPattern = RegExp(
  r'(?:Z|[+-]\d{2}:?\d{2})$',
  caseSensitive: false,
);

/// Zero-knowledge encrypted sync envelope stored by `grimoire_server`.
@immutable
class EncryptedBlobEnvelope._({
  required final String blobId,
  required final String vaultId,
  required final int revision,
  required final CipherSuite cipherSuite,
  required final int keyVersion,
  required final String nonceBase64,
  required final String ciphertextBase64,
  required final DateTime updatedAt,
}) {
  /// Creates and validates an [EncryptedBlobEnvelope].
  factory EncryptedBlobEnvelope({
    required String blobId,
    required String vaultId,
    required int revision,
    required CipherSuite cipherSuite,
    required int keyVersion,
    required String nonceBase64,
    required String ciphertextBase64,
    required DateTime updatedAt,
  }) {
    final trimmedBlobId = blobId.trim();
    if (trimmedBlobId.isEmpty) {
      throw ArgumentError.value(blobId, 'blobId', 'blobId must not be empty.');
    }
    final trimmedVaultId = vaultId.trim();
    if (trimmedVaultId.isEmpty) {
      throw ArgumentError.value(
        vaultId,
        'vaultId',
        'vaultId must not be empty.',
      );
    }
    if (revision < 0) {
      throw ArgumentError.value(
        revision,
        'revision',
        'revision must be non-negative.',
      );
    }
    if (keyVersion < 1) {
      throw ArgumentError.value(
        keyVersion,
        'keyVersion',
        'keyVersion must be >= 1.',
      );
    }
    _requireValidNonEmptyBase64(nonceBase64, 'nonceBase64');
    _requireValidNonEmptyBase64(ciphertextBase64, 'ciphertextBase64');

    return EncryptedBlobEnvelope._(
      blobId: trimmedBlobId,
      vaultId: trimmedVaultId,
      revision: revision,
      cipherSuite: cipherSuite,
      keyVersion: keyVersion,
      nonceBase64: nonceBase64,
      ciphertextBase64: ciphertextBase64,
      updatedAt: updatedAt.toUtc(),
    );
  }

  /// Decodes and validates an [EncryptedBlobEnvelope] from JSON.
  factory EncryptedBlobEnvelope.fromJson(Map<String, Object?> json) {
    final blobId = switch (json['blobId']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'blobId',
        'Expected a string blobId.',
      ),
    };
    final vaultId = switch (json['vaultId']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'vaultId',
        'Expected a string vaultId.',
      ),
    };
    final revision = switch (json['revision']) {
      final int value => value,
      final other => throw ArgumentError.value(
        other,
        'revision',
        'Expected an integer revision.',
      ),
    };
    final cipherSuite = switch (json['cipherSuite']) {
      final String value => CipherSuite.fromName(value),
      final other => throw ArgumentError.value(
        other,
        'cipherSuite',
        'Expected a CipherSuite string.',
      ),
    };
    final keyVersion = switch (json['keyVersion']) {
      final int value => value,
      final other => throw ArgumentError.value(
        other,
        'keyVersion',
        'Expected an integer keyVersion.',
      ),
    };
    final nonceBase64 = switch (json['nonceBase64']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'nonceBase64',
        'Expected a Base64 nonce string.',
      ),
    };
    final ciphertextBase64 = switch (json['ciphertextBase64']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'ciphertextBase64',
        'Expected a Base64 ciphertext string.',
      ),
    };
    final updatedAt = _parseUtcIso(json['updatedAt'], 'updatedAt');

    return EncryptedBlobEnvelope(
      blobId: blobId,
      vaultId: vaultId,
      revision: revision,
      cipherSuite: cipherSuite,
      keyVersion: keyVersion,
      nonceBase64: nonceBase64,
      ciphertextBase64: ciphertextBase64,
      updatedAt: updatedAt,
    );
  }

  /// Serializes this encrypted envelope to JSON.
  Map<String, Object?> toJson() => {
    'blobId': blobId,
    'vaultId': vaultId,
    'revision': revision,
    'cipherSuite': cipherSuite.name,
    'keyVersion': keyVersion,
    'nonceBase64': nonceBase64,
    'ciphertextBase64': ciphertextBase64,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncryptedBlobEnvelope &&
          other.blobId == blobId &&
          other.vaultId == vaultId &&
          other.revision == revision &&
          other.cipherSuite == cipherSuite &&
          other.keyVersion == keyVersion &&
          other.nonceBase64 == nonceBase64 &&
          other.ciphertextBase64 == ciphertextBase64 &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    blobId,
    vaultId,
    revision,
    cipherSuite,
    keyVersion,
    nonceBase64,
    ciphertextBase64,
    updatedAt,
  );
}
