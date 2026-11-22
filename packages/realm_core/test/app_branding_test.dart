import 'package:realm_core/realm_core.dart';
import 'package:test/test.dart';

void main() {
  group('AppBranding', () {
    test('stores operator branding fields including logoUrl', () {
      final logoUrl = Uri.parse('https://cdn.example.com/logo.png?v=1');
      final branding = AppBranding(
        name: 'Example Realm',
        primaryColorArgb: 0xFF6B2D5C,
        tagline: 'Example Tagline',
        logoUrl: logoUrl,
      );

      expect(branding.name, 'Example Realm');
      expect(branding.primaryColorArgb, 0xFF6B2D5C);
      expect(branding.tagline, 'Example Tagline');
      expect(branding.logoUrl, logoUrl);
    });

    test('rejects empty names, invalid colors, and unsafe logoUrl', () {
      expect(
        () => AppBranding(name: '   ', primaryColorArgb: 0xFF000000),
        throwsArgumentError,
      );
      expect(
        () => AppBranding(name: 'Example Realm', primaryColorArgb: 0x00112233),
        throwsArgumentError,
      );
      expect(
        () => AppBranding(
          name: 'Example Realm',
          primaryColorArgb: 0xFF6B2D5C,
          tagline: '  ',
        ),
        throwsArgumentError,
      );
      expect(
        () => AppBranding(
          name: 'Example Realm',
          primaryColorArgb: 0xFF6B2D5C,
          logoUrl: Uri.parse('javascript:alert(1)'),
        ),
        throwsArgumentError,
      );
    });

    test('round-trips JSON and supports value equality and copyWith', () {
      final branding = AppBranding(
        name: 'Example Realm',
        primaryColorArgb: 0xFF6B2D5C,
        tagline: 'Example Tagline',
        logoUrl: Uri.parse('https://cdn.example.com/logo.png'),
      );

      final decoded = AppBranding.fromJson(branding.toJson());
      expect(decoded, equals(branding));
      expect(decoded.hashCode, equals(branding.hashCode));

      final updated = branding.copyWith(name: 'Updated Realm');
      expect(updated.name, 'Updated Realm');
      expect(updated, isNot(equals(branding)));

      final cleared = branding.copyWith(
        tagline: () => null,
        logoUrl: () => null,
      );
      expect(cleared.tagline, isNull);
      expect(cleared.logoUrl, isNull);
    });

    test('VenueBranding is assignable to AppBranding', () {
      final venue = VenueBranding(
        name: 'Example Venue',
        primaryColorArgb: 0xFF6B2D5C,
      );
      expect(venue, isA<AppBranding>());
    });
  });

  group('AppConfig', () {
    test('round-trips JSON and rejects invalid apiBaseUrl', () {
      final config = AppConfig(
        branding: AppBranding(
          name: 'Example Realm',
          primaryColorArgb: 0xFF6B2D5C,
        ),
        hostingMode: .managed,
        apiBaseUrl: Uri.parse('https://api.example.com/v1'),
      );

      final decoded = AppConfig.fromJson(config.toJson());
      expect(decoded, equals(config));

      expect(
        () => AppConfig(
          branding: config.branding,
          apiBaseUrl: Uri.parse('https://example.com/api#frag'),
        ),
        throwsArgumentError,
      );
    });
  });
}
