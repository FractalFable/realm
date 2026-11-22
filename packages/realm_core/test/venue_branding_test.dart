import 'package:realm_core/realm_core.dart';
import 'package:test/test.dart';

void main() {
  group('VenueBranding', () {
    test('stores operator branding fields including logoUrl', () {
      final logoUrl = Uri.parse('https://cdn.example.com/logo.png?v=1');
      final branding = VenueBranding(
        name: 'The Crown',
        primaryColorArgb: 0xFF6B2D5C,
        tagline: 'Neighborhood Pub & Kitchen',
        logoUrl: logoUrl,
      );

      expect(branding.name, 'The Crown');
      expect(branding.primaryColorArgb, 0xFF6B2D5C);
      expect(branding.tagline, 'Neighborhood Pub & Kitchen');
      expect(branding.logoUrl, logoUrl);
    });

    test('rejects empty or whitespace venue names', () {
      for (final invalidName in ['', '   ', '\t\n']) {
        expect(
          () => VenueBranding(name: invalidName, primaryColorArgb: 0xFF000000),
          throwsArgumentError,
        );
      }
    });

    test('rejects empty or whitespace taglines when non-null', () {
      for (final invalidTagline in ['', '   ', '\n']) {
        expect(
          () => VenueBranding(
            name: 'The Crown',
            primaryColorArgb: 0xFF6B2D5C,
            tagline: invalidTagline,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects invalid primaryColorArgb bounds and zero alpha', () {
      for (final invalidColor in [-1, 0x100000000, 0x006B2D5C, 0x00000000]) {
        expect(
          () =>
              VenueBranding(name: 'The Crown', primaryColorArgb: invalidColor),
          throwsArgumentError,
        );
      }
    });

    test('rejects unsafe, relative, or malformed logoUrl values', () {
      final invalidUris = [
        Uri(),
        Uri.parse('/assets/logo.png'),
        Uri.parse('javascript:alert(1)'),
        Uri.parse('file:///etc/passwd'),
        Uri.parse('data:image/png;base64,AAAA'),
        Uri.parse('https:///logo.png'),
        Uri.parse('https://user:pass@example.com/logo.png'),
      ];

      for (final invalidUri in invalidUris) {
        expect(
          () => VenueBranding(
            name: 'The Crown',
            primaryColorArgb: 0xFF6B2D5C,
            logoUrl: invalidUri,
          ),
          throwsArgumentError,
        );
      }
    });

    test('supports value equality, hashCode, toString, and copyWith', () {
      final logoUrl = Uri.parse('https://example.com/logo.png');
      final a = VenueBranding(
        name: 'The Crown',
        primaryColorArgb: 0xFF6B2D5C,
        tagline: 'Pub & Kitchen',
        logoUrl: logoUrl,
      );
      final b = VenueBranding(
        name: 'The Crown',
        primaryColorArgb: 0xFF6B2D5C,
        tagline: 'Pub & Kitchen',
        logoUrl: Uri.parse('https://example.com/logo.png'),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('VenueBranding(name: The Crown'));

      final updated = a.copyWith(name: 'The Anchor');
      expect(updated.name, 'The Anchor');
      expect(updated.tagline, 'Pub & Kitchen');
      expect(updated.logoUrl, logoUrl);
      expect(updated, isNot(equals(a)));

      final cleared = a.copyWith(tagline: () => null, logoUrl: () => null);
      expect(cleared.tagline, isNull);
      expect(cleared.logoUrl, isNull);
    });
  });

  group('VenueConfig', () {
    test('defaults hostingMode to selfHosted', () {
      final branding = VenueBranding(
        name: 'The Crown',
        primaryColorArgb: 0xFF6B2D5C,
      );
      final config = VenueConfig(branding: branding);

      expect(config.hostingMode, HostingMode.selfHosted);
      expect(config.apiBaseUrl, isNull);
    });

    test('accepts dot shorthand for HostingMode and valid apiBaseUrl', () {
      final apiBaseUrl = Uri.parse('https://api.thecrown.example/v1');
      final config = VenueConfig(
        branding: VenueBranding(
          name: 'The Crown',
          primaryColorArgb: 0xFF6B2D5C,
        ),
        hostingMode: .managed,
        apiBaseUrl: apiBaseUrl,
      );

      expect(config.hostingMode, HostingMode.managed);
      expect(config.apiBaseUrl, apiBaseUrl);
    });

    test('rejects unsafe, relative, userinfo, or fragment apiBaseUrl', () {
      final branding = VenueBranding(
        name: 'The Crown',
        primaryColorArgb: 0xFF6B2D5C,
      );
      final invalidUris = [
        Uri(),
        Uri.parse('/api/v1'),
        Uri.parse('ftp://example.com/api'),
        Uri.parse('file:///var/run/api.sock'),
        Uri.parse('https:///api'),
        Uri.parse('https://token@example.com/api'),
        Uri.parse('https://example.com/api#frag'),
      ];

      for (final invalidUri in invalidUris) {
        expect(
          () => VenueConfig(branding: branding, apiBaseUrl: invalidUri),
          throwsArgumentError,
        );
      }
    });

    test('supports value equality, hashCode, toString, and copyWith', () {
      final branding = VenueBranding(
        name: 'The Crown',
        primaryColorArgb: 0xFF6B2D5C,
      );
      final apiUrl = Uri.parse('https://api.example.com');
      final a = VenueConfig(
        branding: branding,
        hostingMode: .managed,
        apiBaseUrl: apiUrl,
      );
      final b = VenueConfig(
        branding: VenueBranding(
          name: 'The Crown',
          primaryColorArgb: 0xFF6B2D5C,
        ),
        hostingMode: .managed,
        apiBaseUrl: Uri.parse('https://api.example.com'),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('HostingMode.managed'));

      final updated = a.copyWith(hostingMode: .selfHosted);
      expect(updated.hostingMode, HostingMode.selfHosted);
      expect(updated.apiBaseUrl, apiUrl);

      final cleared = a.copyWith(apiBaseUrl: () => null);
      expect(cleared.apiBaseUrl, isNull);
    });
  });
}
