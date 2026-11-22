import 'package:realm_core/realm_core.dart';
import 'package:test/test.dart';

void main() {
  group('ClientEndpointConfig', () {
    test(
      'resolves in precedence: explicitOverride > configJson > webOrigin',
      () {
        final overrideUrl = Uri.parse('https://override.example.com');
        final jsonMap = <String, Object?>{
          'apiBaseUrl': 'https://cfg.example.com',
        };
        final webOrigin = Uri.parse('https://web.example.com');

        final fromOverride = ClientEndpointConfig.resolve(
          explicitOverride: overrideUrl,
          configJson: jsonMap,
          webOrigin: webOrigin,
        );
        expect(fromOverride.apiBaseUrl, overrideUrl);

        final fromJson = ClientEndpointConfig.resolve(
          configJson: jsonMap,
          webOrigin: webOrigin,
        );
        expect(fromJson.apiBaseUrl, Uri.parse('https://cfg.example.com'));

        final fromWeb = ClientEndpointConfig.resolve(webOrigin: webOrigin);
        expect(fromWeb.apiBaseUrl, webOrigin);
      },
    );

    test(
      'falls back to webOrigin when configJson apiBaseUrl is null or blank',
      () {
        final webOrigin = Uri.parse('https://web.example.com');

        for (final configJson in <Map<String, Object?>>[
          const {'apiBaseUrl': null},
          const {'apiBaseUrl': ''},
          const {'apiBaseUrl': '   '},
        ]) {
          final resolved = ClientEndpointConfig.resolve(
            configJson: configJson,
            webOrigin: webOrigin,
          );
          expect(resolved.apiBaseUrl, webOrigin);
        }
      },
    );

    test('throws StateError when no endpoint source is configured', () {
      expect(ClientEndpointConfig.resolve, throwsStateError);
      expect(
        () => ClientEndpointConfig.resolve(configJson: const {}),
        throwsStateError,
      );
      expect(
        () =>
            ClientEndpointConfig.resolve(configJson: const {'apiBaseUrl': ''}),
        throwsStateError,
      );
    });

    test('rejects invalid explicitOverride even when fallback exists', () {
      expect(
        () => ClientEndpointConfig.resolve(
          explicitOverride: Uri.parse('ftp://override.example.com'),
          webOrigin: Uri.parse('https://web.example.com'),
        ),
        throwsArgumentError,
      );
      expect(
        () => ClientEndpointConfig.resolve(
          configJson: const {'apiBaseUrl': 42},
          webOrigin: Uri.parse('https://web.example.com'),
        ),
        throwsArgumentError,
      );
      expect(
        () => ClientEndpointConfig.resolve(
          configJson: const {'apiBaseUrl': 'ftp://bad.example.com'},
          webOrigin: Uri.parse('https://web.example.com'),
        ),
        throwsArgumentError,
      );
    });

    test(
      'enforces HTTPS outside loopback unless allowInsecureHttp is true',
      () {
        for (final loopbackUrl in [
          'http://localhost:8080',
          'http://127.0.0.1:8080',
          'http://[::1]:8080',
        ]) {
          final config = ClientEndpointConfig.fromJson({
            'apiBaseUrl': loopbackUrl,
          });
          expect(config.apiBaseUrl.scheme, 'http');
        }

        expect(
          () => ClientEndpointConfig(
            apiBaseUrl: Uri.parse('http://api.example.com'),
          ),
          throwsArgumentError,
        );
        expect(
          () => ClientEndpointConfig.fromJson({
            'apiBaseUrl': 'http://api.example.com',
          }),
          throwsArgumentError,
        );

        final lan = ClientEndpointConfig.resolve(
          configJson: const {'apiBaseUrl': 'http://192.168.1.25:8080'},
          allowInsecureHttp: true,
        );
        expect(lan.apiBaseUrl, Uri.parse('http://192.168.1.25:8080'));
        expect(
          lan.endpoint('/api/v1/bootstrap'),
          Uri.parse('http://192.168.1.25:8080/api/v1/bootstrap'),
        );
      },
    );

    test(
      'rejects invalid, non-HTTP, userinfo, query, fragment, or port URIs',
      () {
        final invalidUrls = [
          Uri.parse('/relative'),
          Uri.parse('ftp://example.com'),
          Uri.parse('https://user@example.com'),
          Uri.parse('https://api.example.com?foo=bar'),
          Uri.parse('https://api.example.com/#section'),
          Uri.parse('https://api.example.com:0'),
          Uri.parse('https://api.example.com:65536'),
          Uri.parse('https://api.example.com%20'),
        ];

        for (final url in invalidUrls) {
          expect(
            () => ClientEndpointConfig(apiBaseUrl: url),
            throwsArgumentError,
          );
        }

        for (final badJson in <Map<String, Object?>>[
          const {'apiBaseUrl': 42},
          const {'apiBaseUrl': ''},
          const {'apiBaseUrl': '   '},
          const {'apiBaseUrl': 'https://api.example.com /v1'},
          const {'apiBaseUrl': 'https://@example.com'},
        ]) {
          expect(
            () => ClientEndpointConfig.fromJson(badJson),
            throwsArgumentError,
          );
        }
      },
    );

    test('accepts IPv6 hosts and resolves endpoint paths cleanly', () {
      final ipv6Config = ClientEndpointConfig(
        apiBaseUrl: Uri.parse('https://[::1]:8443'),
      );
      expect(
        ipv6Config.endpoint('/api/v1/bootstrap'),
        Uri.parse('https://[::1]:8443/api/v1/bootstrap'),
      );

      final prefixed = ClientEndpointConfig(
        apiBaseUrl: Uri.parse('https://api.example.com/v1/'),
      );
      expect(
        prefixed.endpoint('bootstrap'),
        Uri.parse('https://api.example.com/v1/bootstrap'),
      );
      expect(
        prefixed.endpoint('/bootstrap'),
        Uri.parse('https://api.example.com/v1/bootstrap'),
      );

      final withoutTrailingSlash = ClientEndpointConfig(
        apiBaseUrl: Uri.parse('https://api.example.com/v1'),
      );
      expect(
        withoutTrailingSlash.endpoint('/bootstrap'),
        Uri.parse('https://api.example.com/v1/bootstrap'),
      );

      for (final badRelativePath in [
        '../other',
        '%2e%2e/other',
        'https://api.example.com/other',
        'https://user:secret@api.example.com/v1/bootstrap',
        'http://evil.example.com/hook',
        'bootstrap#frag',
        'bootstrap ',
        '   ',
        'bootstrap\n',
      ]) {
        expect(
          () => withoutTrailingSlash.endpoint(badRelativePath),
          throwsArgumentError,
        );
      }
    });

    test('round-trips JSON and supports value equality', () {
      final a = ClientEndpointConfig.fromJson({
        'apiBaseUrl': 'https://api.example.com',
      });
      final b = ClientEndpointConfig(
        apiBaseUrl: Uri.parse('https://api.example.com'),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(ClientEndpointConfig.fromJson(a.toJson()), equals(a));
      expect(a.toString(), contains('https://api.example.com'));
    });
  });
}
