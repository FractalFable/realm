import 'dart:convert';
import 'dart:io';

import 'package:realm_core/realm_core.dart';
import 'package:realm_server_kit/realm_server_kit.dart';
import 'package:relic/relic.dart';
import 'package:test/test.dart';

Future<({int statusCode, String body, String? contentType})> _get(
  HttpClient client,
  int port,
  String path,
) async {
  final request = await client.getUrl(
    Uri(scheme: 'http', host: '127.0.0.1', port: port, path: path),
  );
  final response = await request.close();
  final body = await utf8.decodeStream(response);
  return (
    statusCode: response.statusCode,
    body: body,
    contentType: response.headers.contentType?.mimeType,
  );
}

void main() {
  group('RealmServerSpec', () {
    test('rejects blank serviceName', () {
      expect(
        () => RealmServerSpec(serviceName: '  ', bootstrapPayload: () => {}),
        throwsArgumentError,
      );
    });
  });

  group('createRealmApp', () {
    test(
      'serves /health, /api/v1/bootstrap, custom routes, and 404 on unknown',
      () async {
        final bootstrap = AppBootstrap(
          branding: AppBranding(
            name: 'Example Realm',
            primaryColorArgb: 0xFF283593,
          ),
          capabilities: AppCapabilities(
            aiAssistantEnabled: true,
            enabledModules: const {'example'},
          ),
        );
        final app = createRealmApp(
          RealmServerSpec(
            serviceName: 'example_service',
            bootstrapPayload: bootstrap.toJson,
          ),
          configureRoutes: (router) {
            router.get(
              '/api/v1/custom',
              (_) => jsonError(400, 'BAD_INPUT', 'Missing parameter.'),
            );
          },
        );
        final server = await app.serve(
          address: InternetAddress.loopbackIPv4,
          port: 0,
        );
        final client = HttpClient();
        addTearDown(() async {
          client.close(force: true);
          await app.close();
        });

        final health = await _get(client, server.port, '/health');
        expect(health.statusCode, 200);
        expect(health.contentType, 'application/json');
        expect(
          jsonDecode(health.body),
          equals({'status': 'ok', 'service': 'example_service'}),
        );

        final bootResp = await _get(client, server.port, '/api/v1/bootstrap');
        expect(bootResp.statusCode, 200);
        expect(
          AppBootstrap.fromJson(
            jsonDecode(bootResp.body) as Map<String, Object?>,
          ),
          equals(bootstrap),
        );

        final custom = await _get(client, server.port, '/api/v1/custom');
        expect(custom.statusCode, 400);
        expect(
          jsonDecode(custom.body),
          equals({'code': 'BAD_INPUT', 'message': 'Missing parameter.'}),
        );

        final missing = await _get(client, server.port, '/does-not-exist');
        expect(missing.statusCode, 404);
      },
    );
  });
}
