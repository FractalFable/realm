import 'package:realm_crypto/realm_crypto.dart';
import 'package:test/test.dart';

void main() {
  const kdf = RealmKeyDerivation();

  group('Argon2idParameters', () {
    test('verifies audited OWASP baseline defaults', () {
      const defaults = Argon2idParameters.owaspBaseline;
      expect(defaults.memoryKiB, 19456);
      expect(defaults.iterations, 2);
      expect(defaults.parallelism, 1);
      expect(defaults.hashLength, 32);
    });

    test('validates RFC 9106 memory >= 8 * p, divisibility, and bounds', () {
      final multiLane = Argon2idParameters(
        memoryKiB: 16,
        iterations: 1,
        parallelism: 2,
      );
      expect(multiLane.memoryKiB, 16);
      expect(multiLane.parallelism, 2);

      // Below 8 * parallelism (4 * p <= m < 8 * p) must throw RealmCryptoException
      expect(
        () => Argon2idParameters(memoryKiB: 4, iterations: 1, parallelism: 1),
        throwsA(isA<RealmCryptoException>()),
      );
      // Not divisible by 4 * parallelism (20 % 8 != 0)
      expect(
        () => Argon2idParameters(memoryKiB: 20, iterations: 1, parallelism: 2),
        throwsA(isA<RealmCryptoException>()),
      );
      expect(
        () => Argon2idParameters(memoryKiB: 64, iterations: 0, parallelism: 1),
        throwsA(isA<RealmCryptoException>()),
      );
      expect(
        () => Argon2idParameters(memoryKiB: 64, iterations: 1, parallelism: 0),
        throwsA(isA<RealmCryptoException>()),
      );
      expect(
        () => Argon2idParameters(
          memoryKiB: 64,
          iterations: 1,
          parallelism: 1,
          hashLength: 8,
        ),
        throwsA(isA<RealmCryptoException>()),
      );
    });
  });

  group('RealmKeyDerivation', () {
    test('derives deterministic HKDF-SHA256 subkeys with domain and salt separation', () async {
      final ikm = List<int>.generate(32, (i) => i + 10);
      final saltA = List<int>.generate(16, (i) => i + 1);
      final saltB = List<int>.generate(16, (i) => i + 2);

      final keyA1 = await kdf.deriveSubkeyHkdfSha256(
        inputKeyBytes: ikm,
        salt: saltA,
        info: 'realm:crypto:blob:v1',
      );
      final keyA2 = await kdf.deriveSubkeyHkdfSha256(
        inputKeyBytes: ikm,
        salt: saltA,
        info: 'realm:crypto:blob:v1',
      );
      final keyDiffInfo = await kdf.deriveSubkeyHkdfSha256(
        inputKeyBytes: ikm,
        salt: saltA,
        info: 'realm:crypto:index:v1',
      );
      final keyDiffSalt = await kdf.deriveSubkeyHkdfSha256(
        inputKeyBytes: ikm,
        salt: saltB,
        info: 'realm:crypto:blob:v1',
      );

      expect(keyA1.length, 32);
      expect(keyA1, equals(keyA2));
      expect(keyA1, isNot(equals(keyDiffInfo)));
      expect(keyA1, isNot(equals(keyDiffSalt)));

      await expectLater(
        kdf.deriveSubkeyHkdfSha256(
          inputKeyBytes: const [1, 2, 3],
          info: 'realm:crypto:blob:v1',
        ),
        throwsA(isA<RealmCryptoException>()),
      );
      await expectLater(
        kdf.deriveSubkeyHkdfSha256(inputKeyBytes: ikm, info: '   '),
        throwsA(isA<RealmCryptoException>()),
      );
      await expectLater(
        kdf.deriveSubkeyHkdfSha256(
          inputKeyBytes: ikm,
          info: 'realm:crypto:blob:v1',
          outputLength: 8,
        ),
        throwsA(isA<RealmCryptoException>()),
      );
      await expectLater(
        kdf.deriveSubkeyHkdfSha256(
          inputKeyBytes: ikm,
          info: 'realm:crypto:blob:v1',
          outputLength: 255 * 32 + 1,
        ),
        throwsA(isA<RealmCryptoException>()),
      );
    });

    test(
      'derives deterministic Argon2id keys with salt separation and bounds',
      () async {
        final saltA = List<int>.generate(16, (i) => i + 3);
        final saltB = List<int>.generate(16, (i) => i + 9);
        // Lightweight parameters used only to keep unit test execution fast;
        // production defaults are verified in Argon2idParameters.owaspBaseline.
        final testParams = Argon2idParameters(
          memoryKiB: 64,
          iterations: 1,
          parallelism: 1,
        );

        final master1 = await kdf.deriveMasterKeyArgon2id(
          passphrase: 'correct-horse-battery-staple',
          salt: saltA,
          parameters: testParams,
        );
        final master2 = await kdf.deriveMasterKeyArgon2id(
          passphrase: 'correct-horse-battery-staple',
          salt: saltA,
          parameters: testParams,
        );
        final differentPass = await kdf.deriveMasterKeyArgon2id(
          passphrase: 'other-passphrase',
          salt: saltA,
          parameters: testParams,
        );
        final differentSalt = await kdf.deriveMasterKeyArgon2id(
          passphrase: 'correct-horse-battery-staple',
          salt: saltB,
          parameters: testParams,
        );

        expect(master1.length, 32);
        expect(master1, equals(master2));
        expect(master1, isNot(equals(differentPass)));
        expect(master1, isNot(equals(differentSalt)));

        await expectLater(
          kdf.deriveMasterKeyArgon2id(
            passphrase: '',
            salt: saltA,
            parameters: testParams,
          ),
          throwsA(isA<RealmCryptoException>()),
        );
        await expectLater(
          kdf.deriveMasterKeyArgon2id(
            passphrase: 'valid-passphrase',
            salt: const [1, 2, 3],
            parameters: testParams,
          ),
          throwsA(isA<RealmCryptoException>()),
        );
      },
    );
  });
}
