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

    test('rejects invalid memory, iteration, parallelism, or hashLength', () {
      expect(
        () => Argon2idParameters(memoryKiB: 10, iterations: 1, parallelism: 1),
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
    test(
      'derives deterministic HKDF-SHA256 subkeys with domain separation',
      () async {
        final ikm = List<int>.generate(32, (i) => i + 10);
        final salt = List<int>.generate(16, (i) => i + 1);

        final keyA1 = await kdf.deriveSubkeyHkdfSha256(
          inputKeyBytes: ikm,
          salt: salt,
          info: 'realm:grimoire:blob:v1',
        );
        final keyA2 = await kdf.deriveSubkeyHkdfSha256(
          inputKeyBytes: ikm,
          salt: salt,
          info: 'realm:grimoire:blob:v1',
        );
        final keyB = await kdf.deriveSubkeyHkdfSha256(
          inputKeyBytes: ikm,
          salt: salt,
          info: 'realm:grimoire:index:v1',
        );

        expect(keyA1.length, 32);
        expect(keyA1, equals(keyA2));
        expect(keyA1, isNot(equals(keyB)));
      },
    );

    test(
      'derives deterministic Argon2id keys and rejects short salts',
      () async {
        final salt = List<int>.generate(16, (i) => i + 3);
        // Lightweight parameters used only to keep unit test execution fast;
        // production defaults are verified in Argon2idParameters.owaspBaseline.
        final testParams = Argon2idParameters(
          memoryKiB: 64,
          iterations: 1,
          parallelism: 1,
        );

        final master1 = await kdf.deriveMasterKeyArgon2id(
          passphrase: 'correct-horse-battery-staple',
          salt: salt,
          parameters: testParams,
        );
        final master2 = await kdf.deriveMasterKeyArgon2id(
          passphrase: 'correct-horse-battery-staple',
          salt: salt,
          parameters: testParams,
        );
        final differentPass = await kdf.deriveMasterKeyArgon2id(
          passphrase: 'other-passphrase',
          salt: salt,
          parameters: testParams,
        );

        expect(master1.length, 32);
        expect(master1, equals(master2));
        expect(master1, isNot(equals(differentPass)));

        await expectLater(
          kdf.deriveMasterKeyArgon2id(
            passphrase: '',
            salt: salt,
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
