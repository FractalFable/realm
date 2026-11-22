import 'package:tavern_core/tavern_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('performs integer minor-unit arithmetic for matching currencies', () {
      final a = Money(minorUnits: 450, currencyCode: 'EUR');
      final b = Money(minorUnits: 275, currencyCode: 'EUR');

      expect(a + b, Money(minorUnits: 725, currencyCode: 'EUR'));
      expect(a - b, Money(minorUnits: 175, currencyCode: 'EUR'));

      final decoded = Money.fromJson(a.toJson());
      expect(decoded, equals(a));
    });

    test('rejects invalid currency codes and cross-currency arithmetic', () {
      for (final invalid in ['', 'eu', 'eur', 'EURO', '123']) {
        expect(
          () => Money(minorUnits: 100, currencyCode: invalid),
          throwsArgumentError,
        );
      }

      final eur = Money(minorUnits: 100, currencyCode: 'EUR');
      final usd = Money(minorUnits: 100, currencyCode: 'USD');
      expect(() => eur + usd, throwsArgumentError);
      expect(() => eur - usd, throwsArgumentError);
      expect(() => Money.fromJson({'minorUnits': '100'}), throwsArgumentError);
    });
  });

  group('LocalizedText', () {
    test('resolves exact locale, base language, and en fallback', () {
      final text = LocalizedText({
        'en': 'House Lager',
        'sl': 'Hisno svetlo pivo',
      });

      expect(text.resolve('sl'), 'Hisno svetlo pivo');
      expect(text.resolve('sl-SI'), 'Hisno svetlo pivo');
      expect(text.resolve('de'), 'House Lager');

      final decoded = LocalizedText.fromJson(text.toJson());
      expect(decoded, equals(text));
    });

    test('rejects empty maps, invalid locale tags, and blank text', () {
      expect(() => LocalizedText(const {}), throwsArgumentError);
      expect(() => LocalizedText({'123': 'Hello'}), throwsArgumentError);
      expect(() => LocalizedText({'en': '   '}), throwsArgumentError);
      expect(() => LocalizedText.fromJson({'en': 42}), throwsArgumentError);
    });
  });

  group('TableCode', () {
    test('accepts unguessable URL-safe codes and round-trips JSON', () {
      final code = TableCode(value: 'tbl_9fK2mP7xQ4vR');
      expect(TableCode.fromJson(code.toJson()), equals(code));
    });

    test('rejects short, numeric-only, or unsafe table codes', () {
      for (final invalid in [
        '',
        'table1',
        '123456789012',
        'short_code',
        'tbl/../../etc',
        'tbl with space',
      ]) {
        expect(() => TableCode(value: invalid), throwsArgumentError);
      }
    });
  });

  group('Venue re-exports', () {
    test('re-exports VenueBootstrap and VenueBranding cleanly', () {
      final bootstrap = VenueBootstrap(
        branding: VenueBranding(
          name: 'Example Venue',
          primaryColorArgb: 0xFF6B2D5C,
        ),
        capabilities: const VenueCapabilities(onlineOrderingEnabled: true),
      );

      final decoded = VenueBootstrap.fromJson(bootstrap.toJson());
      expect(decoded, equals(bootstrap));
    });
  });
}
