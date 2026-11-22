import 'package:realm_core/realm_core.dart';
import 'package:test/test.dart';

void main() {
  group('AppCapabilities', () {
    test('defaults aiAssistantEnabled to false and modules empty', () {
      final capabilities = AppCapabilities();

      expect(capabilities.aiAssistantEnabled, isFalse);
      expect(capabilities.enabledModules, isEmpty);
      expect(capabilities.supportsModule('grimoire'), isFalse);
    });

    test('normalizes module names, round-trips JSON, and rejects blanks', () {
      final capabilities = AppCapabilities(
        aiAssistantEnabled: true,
        enabledModules: const {' grimoire ', 'tavern'},
      );

      expect(capabilities.supportsModule('grimoire'), isTrue);
      expect(capabilities.supportsModule('tavern'), isTrue);

      final decoded = AppCapabilities.fromJson(capabilities.toJson());
      expect(decoded, equals(capabilities));
      expect(decoded.hashCode, equals(capabilities.hashCode));

      expect(
        () => AppCapabilities(enabledModules: const {'   '}),
        throwsArgumentError,
      );
      expect(
        () => AppCapabilities.fromJson({'enabledModules': 'not-a-list'}),
        throwsArgumentError,
      );
      expect(
        () => AppCapabilities.fromJson({
          'enabledModules': [123],
        }),
        throwsArgumentError,
      );
    });
  });

  group('AppBootstrap', () {
    test('round-trips JSON and supports minimal defaults', () {
      final branding = AppBranding(
        name: 'Example Realm',
        primaryColorArgb: 0xFF283593,
      );
      final bootstrap = AppBootstrap(
        branding: branding,
        capabilities: AppCapabilities(
          aiAssistantEnabled: true,
          enabledModules: const {'grimoire'},
        ),
        hostingMode: .managed,
      );

      final decoded = AppBootstrap.fromJson(bootstrap.toJson());
      expect(decoded, equals(bootstrap));

      final minimal = AppBootstrap.fromJson({'branding': branding.toJson()});
      expect(minimal.capabilities.aiAssistantEnabled, isFalse);
      expect(minimal.capabilities.enabledModules, isEmpty);
      expect(minimal.hostingMode, HostingMode.selfHosted);
    });

    test('rejects invalid payloads', () {
      expect(
        () => AppBootstrap.fromJson({'branding': 'invalid'}),
        throwsArgumentError,
      );
      expect(
        () => AppBootstrap.fromJson({
          'branding': {'name': 'Example Realm', 'primaryColorArgb': 0xFF283593},
          'capabilities': 'invalid',
        }),
        throwsArgumentError,
      );
    });
  });
}
