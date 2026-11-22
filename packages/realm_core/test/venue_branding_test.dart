import 'package:realm_core/realm_core.dart';
import 'package:test/test.dart';

void main() {
  group('VenueBranding', () {
    test('stores operator branding fields including logoUrl', () {
      final logoUrl = Uri.parse('https://cdn.example.com/logo.png?v=1');
      final branding = VenueBranding(
        name: 'Example Venue',
        primaryColorArgb: 0xFF6B2D5C,
        tagline: 'Example Tagline',
        logoUrl: logoUrl,
      );

      expect(branding.name, 'Example Venue');
      expect(branding.primaryColorArgb, 0xFF6B2D5C);
      expect(branding.tagline, 'Example Tagline');
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
            name: 'Example Venue',
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
          () => VenueBranding(
            name: 'Example Venue',
            primaryColorArgb: invalidColor,
          ),
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
            name: 'Example Venue',
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
        name: 'Example Venue',
        primaryColorArgb: 0xFF6B2D5C,
        tagline: 'Example Tagline',
        logoUrl: logoUrl,
      );
      final b = VenueBranding(
        name: 'Example Venue',
        primaryColorArgb: 0xFF6B2D5C,
        tagline: 'Example Tagline',
        logoUrl: Uri.parse('https://example.com/logo.png'),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('VenueBranding(name: Example Venue'));

      final updated = a.copyWith(name: 'Updated Venue');
      expect(updated.name, 'Updated Venue');
      expect(updated.tagline, 'Example Tagline');
      expect(updated.logoUrl, logoUrl);
      expect(updated, isNot(equals(a)));

      final cleared = a.copyWith(tagline: () => null, logoUrl: () => null);
      expect(cleared.tagline, isNull);
      expect(cleared.logoUrl, isNull);
    });

    test('round-trips valid JSON and rejects malformed JSON', () {
      final branding = VenueBranding(
        name: 'Example Venue',
        primaryColorArgb: 0xFF6B2D5C,
        tagline: 'Example Tagline',
        logoUrl: Uri.parse('https://cdn.example.com/logo.png'),
      );

      final decoded = VenueBranding.fromJson(branding.toJson());
      expect(decoded, equals(branding));

      expect(
        () => VenueBranding.fromJson({'name': 123, 'primaryColorArgb': 0xFF1}),
        throwsArgumentError,
      );
      expect(
        () => VenueBranding.fromJson({'primaryColorArgb': 0xFF6B2D5C}),
        throwsArgumentError,
      );
      expect(
        () => VenueBranding.fromJson({'name': 'Example Venue'}),
        throwsArgumentError,
      );
      expect(
        () => VenueBranding.fromJson({
          'name': 'Example Venue',
          'primaryColorArgb': 0xFF6B2D5C,
          'logoUrl': 'javascript:alert(1)',
        }),
        throwsArgumentError,
      );
    });
  });

  group('VenueConfig', () {
    test('defaults hostingMode to selfHosted', () {
      final branding = VenueBranding(
        name: 'Example Venue',
        primaryColorArgb: 0xFF6B2D5C,
      );
      final config = VenueConfig(branding: branding);

      expect(config.hostingMode, HostingMode.selfHosted);
      expect(config.apiBaseUrl, isNull);
    });

    test('accepts dot shorthand for HostingMode and valid apiBaseUrl', () {
      final apiBaseUrl = Uri.parse('https://api.example.com/v1');
      final config = VenueConfig(
        branding: VenueBranding(
          name: 'Example Venue',
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
        name: 'Example Venue',
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
        name: 'Example Venue',
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
          name: 'Example Venue',
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

    test('round-trips valid JSON and rejects unknown hostingMode', () {
      final config = VenueConfig(
        branding: VenueBranding(
          name: 'Example Venue',
          primaryColorArgb: 0xFF6B2D5C,
        ),
        hostingMode: .managed,
        apiBaseUrl: Uri.parse('https://api.example.com/v1'),
      );

      final decoded = VenueConfig.fromJson(config.toJson());
      expect(decoded, equals(config));

      expect(
        () => VenueConfig.fromJson({
          'branding': config.branding.toJson(),
          'hostingMode': 'unknown',
        }),
        throwsArgumentError,
      );
      expect(
        () => VenueConfig.fromJson(const {'hostingMode': 'managed'}),
        throwsArgumentError,
      );
    });
  });
}
