import 'package:realm_core/realm_core.dart';
import 'package:test/test.dart';

void main() {
  group('VenueCapabilities', () {
    test('defaults all capabilities to false', () {
      const capabilities = VenueCapabilities();

      expect(capabilities.aiAssistantEnabled, isFalse);
      expect(capabilities.onlineOrderingEnabled, isFalse);
      expect(capabilities.paymentsEnabled, isFalse);
    });

    test('round-trips JSON and validates field types', () {
      const capabilities = VenueCapabilities(
        aiAssistantEnabled: true,
        paymentsEnabled: true,
      );

      final decoded = VenueCapabilities.fromJson(capabilities.toJson());
      expect(decoded, equals(capabilities));

      final updated = capabilities.copyWith(onlineOrderingEnabled: true);
      expect(updated.onlineOrderingEnabled, isTrue);
      expect(updated, isNot(equals(capabilities)));

      expect(
        () => VenueCapabilities.fromJson({'aiAssistantEnabled': 'yes'}),
        throwsArgumentError,
      );
    });
  });

  group('VenueBootstrap', () {
    test('round-trips JSON with defaults and full values', () {
      final branding = VenueBranding(
        name: 'Example Venue',
        primaryColorArgb: 0xFF6B2D5C,
      );
      final bootstrap = VenueBootstrap(
        branding: branding,
        capabilities: const VenueCapabilities(
          aiAssistantEnabled: true,
          onlineOrderingEnabled: true,
        ),
        hostingMode: .managed,
      );

      final decoded = VenueBootstrap.fromJson(bootstrap.toJson());
      expect(decoded, equals(bootstrap));
      expect(decoded.hostingMode, HostingMode.managed);
      expect(decoded.capabilities.aiAssistantEnabled, isTrue);

      final minimal = VenueBootstrap.fromJson({'branding': branding.toJson()});
      expect(minimal.capabilities, equals(const VenueCapabilities()));
      expect(minimal.hostingMode, HostingMode.selfHosted);

      final updated = minimal.copyWith(
        hostingMode: .managed,
        capabilities: const VenueCapabilities(paymentsEnabled: true),
      );
      expect(updated.hostingMode, HostingMode.managed);
      expect(updated.capabilities.paymentsEnabled, isTrue);
      expect(updated, isNot(equals(minimal)));
    });

    test('rejects invalid branding, capabilities, or hostingMode in JSON', () {
      expect(
        () => VenueBootstrap.fromJson({'branding': 'not-a-map'}),
        throwsArgumentError,
      );
      expect(
        () => VenueBootstrap.fromJson({
          'branding': {'name': 'Example Venue', 'primaryColorArgb': 0xFF6B2D5C},
          'capabilities': 'not-a-map',
        }),
        throwsArgumentError,
      );
      expect(
        () => VenueBootstrap.fromJson({
          'branding': {'name': 'Example Venue', 'primaryColorArgb': 0xFF6B2D5C},
          'hostingMode': 'unknown',
        }),
        throwsArgumentError,
      );
    });
  });
}
