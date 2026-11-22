import 'package:realm_core/realm_core.dart';
import 'package:test/test.dart';

void main() {
  group('IntegrationKeyStatus', () {
    test('defaults to unconfigured and supports configured status JSON', () {
      final unconfigured = IntegrationKeyStatus(provider: .aiLlm);
      expect(unconfigured.isConfigured, isFalse);
      expect(unconfigured.keyHint, isNull);
      expect(unconfigured.updatedAt, isNull);

      final updatedAt = DateTime.utc(2026, 11, 22, 12);
      final configured = IntegrationKeyStatus(
        provider: .payments,
        source: .encryptedVault,
        keyHint: '...4a9c',
        updatedAt: updatedAt,
      );
      expect(configured.isConfigured, isTrue);

      final roundTripped = IntegrationKeyStatus.fromJson(configured.toJson());
      expect(roundTripped, equals(configured));
      expect(roundTripped.hashCode, equals(configured.hashCode));
    });

    test('supports email and sms providers and all key sources', () {
      final emailStatus = IntegrationKeyStatus(
        provider: .email,
        source: .environment,
        keyHint: '***9f',
      );
      final smsStatus = IntegrationKeyStatus(
        provider: .sms,
        source: .encryptedVault,
        keyHint: '...a',
      );

      expect(
        IntegrationKeyStatus.fromJson(emailStatus.toJson()),
        equals(emailStatus),
      );
      expect(
        IntegrationKeyStatus.fromJson(smsStatus.toJson()),
        equals(smsStatus),
      );
    });

    test('redacts keyHint in toString and never leaks rejected values', () {
      const secret = 'sk_live_SUPER_SECRET_123456';
      final configured = IntegrationKeyStatus(
        provider: .aiLlm,
        source: .encryptedVault,
        keyHint: '...4a9c',
      );

      expect(configured.toString(), contains('hasKeyHint: true'));
      expect(configured.toString(), isNot(contains('4a9c')));

      expect(
        () => IntegrationKeyStatus(
          provider: .aiLlm,
          source: .environment,
          keyHint: secret,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'toString',
            allOf(isNot(contains(secret)), isNot(contains('SUPER_SECRET'))),
          ),
        ),
      );

      expect(
        () => IntegrationKeyStatus(provider: .aiLlm, keyHint: '...1234'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'toString',
            isNot(contains('...1234')),
          ),
        ),
      );
    });

    test('rejects unconfigured integrations with keyHint or updatedAt', () {
      expect(
        () => IntegrationKeyStatus(provider: .aiLlm, keyHint: '...1234'),
        throwsArgumentError,
      );
      expect(
        () => IntegrationKeyStatus(
          provider: .aiLlm,
          updatedAt: DateTime.utc(2026, 11, 22),
        ),
        throwsArgumentError,
      );
      expect(
        () => IntegrationKeyStatus.fromJson({
          'provider': 'aiLlm',
          'keyHint': '...1234',
        }),
        throwsArgumentError,
      );
    });

    test('enforces masked hint boundaries and rejects control chars', () {
      for (final validHint in ['...a', '...4a9c', '***1', '***9f!~']) {
        final status = IntegrationKeyStatus(
          provider: .aiLlm,
          source: .environment,
          keyHint: validHint,
        );
        expect(status.keyHint, validHint);
      }

      for (final badHint in [
        '',
        '   ',
        'sk_live_',
        '1234',
        '...',
        '***',
        '..abcd',
        '...12345',
        '***12345',
        '...a b',
        '...a\x1bb',
        '...a\nb',
        '...abcd\n',
      ]) {
        expect(
          () => IntegrationKeyStatus(
            provider: .aiLlm,
            source: .environment,
            keyHint: badHint,
          ),
          throwsArgumentError,
        );
      }
    });

    test('normalizes local DateTime to UTC and requires timezone in JSON', () {
      final localTime = DateTime(2026, 11, 22, 12, 30);
      final status = IntegrationKeyStatus(
        provider: .payments,
        source: .encryptedVault,
        keyHint: '...abcd',
        updatedAt: localTime,
      );

      expect(status.updatedAt?.isUtc, isTrue);
      expect(IntegrationKeyStatus.fromJson(status.toJson()), equals(status));

      final offsetDecoded = IntegrationKeyStatus.fromJson({
        'provider': 'payments',
        'source': 'encryptedVault',
        'keyHint': '...abcd',
        'updatedAt': '2026-11-22T14:00:00+02:00',
      });
      expect(offsetDecoded.updatedAt, DateTime.utc(2026, 11, 22, 12));

      expect(
        () => IntegrationKeyStatus.fromJson({
          'provider': 'payments',
          'source': 'encryptedVault',
          'updatedAt': '2026-11-22T12:00:00',
        }),
        throwsArgumentError,
      );
    });

    test('supports copyWith clearing and validates JSON input types', () {
      final status = IntegrationKeyStatus(
        provider: .posFiscal,
        source: .encryptedVault,
        keyHint: '...99ff',
        updatedAt: DateTime.utc(2026, 11, 22),
      );

      final cleared = status.copyWith(
        source: .unconfigured,
        keyHint: () => null,
        updatedAt: () => null,
      );
      expect(cleared.isConfigured, isFalse);
      expect(cleared.keyHint, isNull);
      expect(cleared.updatedAt, isNull);

      expect(
        () => status.copyWith(source: .unconfigured, keyHint: () => null),
        throwsArgumentError,
      );

      for (final secretFieldJson in <Map<String, Object?>>[
        {'provider': 'sk_live_SECRET_VALUE'},
        {'provider': 'aiLlm', 'source': 'sk_live_SECRET_VALUE'},
      ]) {
        expect(
          () => IntegrationKeyStatus.fromJson(secretFieldJson),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'toString',
              isNot(contains('sk_live_SECRET_VALUE')),
            ),
          ),
        );
      }

      for (final badJson in <Map<String, Object?>>[
        {'provider': 'unknown'},
        {'provider': 123},
        {'provider': 'aiLlm', 'source': 'unknown'},
        {'provider': 'aiLlm', 'source': 99},
        {'provider': 'aiLlm', 'source': 'environment', 'keyHint': 123},
        {'provider': 'aiLlm', 'source': 'environment', 'updatedAt': 123},
        {
          'provider': 'aiLlm',
          'source': 'environment',
          'updatedAt': 'not-a-dateZ',
        },
      ]) {
        expect(
          () => IntegrationKeyStatus.fromJson(badJson),
          throwsArgumentError,
        );
      }
    });
  });
}
