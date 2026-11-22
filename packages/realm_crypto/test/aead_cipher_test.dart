import 'dart:convert';
import 'dart:typed_data';

import 'package:realm_crypto/realm_crypto.dart';
import 'package:test/test.dart';

void main() {
  const cipher = RealmAeadCipher();
  final validKey = List<int>.generate(32, (i) => i + 1);
  final wrongKey = List<int>.generate(32, (i) => 255 - i);
  final aad = encodeCanonicalAad(const [
    'vault-1',
    'blob-1',
    '1',
    '1',
    'xchacha20Poly1305',
  ]);

  group('encodeCanonicalAad', () {
    test('avoids boundary collisions between differently split strings', () {
      final first = encodeCanonicalAad(const ['ab', 'c']);
      final second = encodeCanonicalAad(const ['a', 'bc']);
      expect(first, isNot(equals(second)));
    });
  });

  group('RealmAeadCipher', () {
    for (final suite in RealmCipherSuite.values) {
      test(
        'round-trips ${suite.name} (non-empty and empty) with unique nonces',
        () async {
          final plaintext = utf8.encode('Top secret E2EE content');
          final sealedA = await cipher.encrypt(
            suite: suite,
            keyBytes: validKey,
            plaintext: plaintext,
            aad: aad,
          );
          final sealedB = await cipher.encrypt(
            suite: suite,
            keyBytes: validKey,
            plaintext: plaintext,
            aad: aad,
          );

          expect(sealedA.nonce.length, suite.nonceLength);
          expect(sealedA.mac.length, suite.macLength);
          expect(sealedA.nonce, isNot(equals(sealedB.nonce)));

          final decrypted = await cipher.decrypt(
            payload: sealedA,
            keyBytes: validKey,
            aad: aad,
          );
          expect(decrypted, equals(plaintext));

          final emptySealed = await cipher.encrypt(
            suite: suite,
            keyBytes: validKey,
            plaintext: const [],
            aad: aad,
          );
          expect(
            await cipher.decrypt(
              payload: emptySealed,
              keyBytes: validKey,
              aad: aad,
            ),
            isEmpty,
          );

          final reparsed = SealedPayload.fromCiphertextAndMac(
            cipherSuite: suite,
            nonce: base64Decode(sealedA.nonceBase64),
            combinedCiphertextAndMac: base64Decode(
              sealedA.ciphertextAndMacBase64,
            ),
          );
          expect(
            await cipher.decrypt(
              payload: reparsed,
              keyBytes: validKey,
              aad: aad,
            ),
            equals(plaintext),
          );
        },
      );

      test(
        'rejects ciphertext/MAC/nonce tampering, wrong key, and AAD swap for ${suite.name}',
        () async {
          final sealed = await cipher.encrypt(
            suite: suite,
            keyBytes: validKey,
            plaintext: utf8.encode('Authentic payload'),
            aad: aad,
          );

          final tamperedCiphertext = Uint8List.fromList(sealed.ciphertext);
          tamperedCiphertext[0] ^= 0x01;
          await expectLater(
            cipher.decrypt(
              payload: SealedPayload(
                cipherSuite: sealed.cipherSuite,
                nonce: sealed.nonce,
                ciphertext: tamperedCiphertext,
                mac: sealed.mac,
              ),
              keyBytes: validKey,
              aad: aad,
            ),
            throwsA(isA<RealmCryptoException>()),
          );

          final tamperedMac = Uint8List.fromList(sealed.mac);
          tamperedMac[0] ^= 0x01;
          await expectLater(
            cipher.decrypt(
              payload: SealedPayload(
                cipherSuite: sealed.cipherSuite,
                nonce: sealed.nonce,
                ciphertext: sealed.ciphertext,
                mac: tamperedMac,
              ),
              keyBytes: validKey,
              aad: aad,
            ),
            throwsA(isA<RealmCryptoException>()),
          );

          final tamperedNonce = Uint8List.fromList(sealed.nonce);
          tamperedNonce[0] ^= 0x01;
          await expectLater(
            cipher.decrypt(
              payload: SealedPayload(
                cipherSuite: sealed.cipherSuite,
                nonce: tamperedNonce,
                ciphertext: sealed.ciphertext,
                mac: sealed.mac,
              ),
              keyBytes: validKey,
              aad: aad,
            ),
            throwsA(isA<RealmCryptoException>()),
          );

          await expectLater(
            cipher.decrypt(payload: sealed, keyBytes: wrongKey, aad: aad),
            throwsA(isA<RealmCryptoException>()),
          );

          final swappedAad = encodeCanonicalAad(const [
            'vault-2',
            'blob-1',
            '1',
            '1',
            'xchacha20Poly1305',
          ]);
          await expectLater(
            cipher.decrypt(
              payload: sealed,
              keyBytes: validKey,
              aad: swappedAad,
            ),
            throwsA(isA<RealmCryptoException>()),
          );
        },
      );
    }

    test(
      'validates encrypt/decrypt guards and truncated SealedPayload',
      () async {
        await expectLater(
          cipher.encrypt(
            suite: .aes256Gcm,
            keyBytes: const [1, 2, 3],
            plaintext: const [4, 5],
            aad: aad,
          ),
          throwsA(isA<RealmCryptoException>()),
        );

        await expectLater(
          cipher.encrypt(
            suite: .aes256Gcm,
            keyBytes: validKey,
            plaintext: const [4, 5],
            aad: const [],
          ),
          throwsA(isA<RealmCryptoException>()),
        );

        final validSealed = await cipher.encrypt(
          suite: .aes256Gcm,
          keyBytes: validKey,
          plaintext: const [1, 2, 3],
          aad: aad,
        );
        await expectLater(
          cipher.decrypt(
            payload: validSealed,
            keyBytes: const [1, 2, 3],
            aad: aad,
          ),
          throwsA(isA<RealmCryptoException>()),
        );
        await expectLater(
          cipher.decrypt(
            payload: validSealed,
            keyBytes: validKey,
            aad: const [],
          ),
          throwsA(isA<RealmCryptoException>()),
        );

        expect(
          () => SealedPayload(
            cipherSuite: .aes256Gcm,
            nonce: List<int>.filled(24, 0),
            ciphertext: const [1],
            mac: List<int>.filled(16, 0),
          ),
          throwsA(isA<RealmCryptoException>()),
        );

        expect(
          () => SealedPayload.fromCiphertextAndMac(
            cipherSuite: .aes256Gcm,
            nonce: List<int>.filled(12, 0),
            combinedCiphertextAndMac: List<int>.filled(15, 0),
          ),
          throwsA(isA<RealmCryptoException>()),
        );
      },
    );
  });
}
