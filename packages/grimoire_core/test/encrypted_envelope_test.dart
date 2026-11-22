import 'dart:convert';

import 'package:grimoire_core/grimoire_core.dart';
import 'package:test/test.dart';

void main() {
  group('EncryptedBlobEnvelope', () {
    test('round-trips valid envelope and normalizes updatedAt to UTC', () {
      final envelope = EncryptedBlobEnvelope(
        blobId: 'note-1',
        vaultId: 'vault-abc',
        revision: 4,
        cipherSuite: .xchacha20Poly1305,
        keyVersion: 2,
        nonceBase64: base64Encode(List<int>.filled(24, 7)),
        ciphertextBase64: base64Encode(List<int>.filled(32, 9)),
        updatedAt: DateTime.parse('2026-11-22T12:00:00+02:00'),
      );

      expect(envelope.updatedAt.isUtc, isTrue);
      final decoded = EncryptedBlobEnvelope.fromJson(envelope.toJson());
      expect(decoded, equals(envelope));
    });

    test('rejects invalid Base64, empty IDs, and bad versions', () {
      final validNonce = base64Encode(List<int>.filled(12, 1));
      final validCipher = base64Encode(List<int>.filled(16, 2));
      final ts = DateTime.utc(2026, 11, 22, 12);

      expect(
        () => EncryptedBlobEnvelope(
          blobId: ' ',
          vaultId: 'v1',
          revision: 0,
          cipherSuite: .aes256Gcm,
          keyVersion: 1,
          nonceBase64: validNonce,
          ciphertextBase64: validCipher,
          updatedAt: ts,
        ),
        throwsArgumentError,
      );

      expect(
        () => EncryptedBlobEnvelope(
          blobId: 'b1',
          vaultId: 'v1',
          revision: 0,
          cipherSuite: .aes256Gcm,
          keyVersion: 0,
          nonceBase64: validNonce,
          ciphertextBase64: validCipher,
          updatedAt: ts,
        ),
        throwsArgumentError,
      );

      expect(
        () => EncryptedBlobEnvelope(
          blobId: 'b1',
          vaultId: 'v1',
          revision: 0,
          cipherSuite: .aes256Gcm,
          keyVersion: 1,
          nonceBase64: '!!!not-base64!!!',
          ciphertextBase64: validCipher,
          updatedAt: ts,
        ),
        throwsArgumentError,
      );

      expect(
        () => EncryptedBlobEnvelope(
          blobId: 'b1',
          vaultId: 'v1',
          revision: 0,
          cipherSuite: .aes256Gcm,
          keyVersion: 1,
          nonceBase64: validNonce,
          ciphertextBase64: '',
          updatedAt: ts,
        ),
        throwsArgumentError,
      );
    });
  });
}
