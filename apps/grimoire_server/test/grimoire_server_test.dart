import 'dart:convert';
import 'dart:io';

import 'package:grimoire_server/grimoire_server.dart';
import 'package:realm_core/realm_core.dart';
import 'package:relic/relic.dart';
import 'package:test/test.dart';

Future<({int statusCode, Map<String, Object?> body})> _getJson(
  HttpClient client,
  int port,
  String path,
) async {
  final request = await client.getUrl(
    Uri(scheme: 'http', host: '127.0.0.1', port: port, path: path),
  );
  final response = await request.close();
  final raw = await utf8.decodeStream(response);
  return (
    statusCode: response.statusCode,
    body: jsonDecode(raw) as Map<String, Object?>,
  );
}

void main() {
  test(
    'grimoire_server serves health, bootstrap, and zero-knowledge status',
    () async {
      final bootstrap = AppBootstrap(
        branding: AppBranding(
          name: 'Example Grimoire',
          primaryColorArgb: 0xFF283593,
        ),
        capabilities: AppCapabilities(
          aiAssistantEnabled: true,
          enabledModules: const {'grimoire'},
        ),
      );
      final app = createGrimoireServerApp(bootstrap);
      final server = await app.serve(
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      final client = HttpClient();
      addTearDown(() async {
        client.close(force: true);
        await app.close();
      });

      final health = await _getJson(client, server.port, '/health');
      expect(health.statusCode, 200);
      expect(health.body['service'], 'grimoire_server');

      final boot = await _getJson(client, server.port, '/api/v1/bootstrap');
      expect(boot.statusCode, 200);
      expect(AppBootstrap.fromJson(boot.body), equals(bootstrap));

      final status = await _getJson(
        client,
        server.port,
        '/api/v1/grimoire/status',
      );
      expect(status.statusCode, 200);
      expect(status.body['app'], 'grimoire');
      expect(status.body['zeroKnowledgeSync'], isTrue);
      expect(
        status.body['supportedCiphers'],
        equals(['xchacha20Poly1305', 'aes256Gcm']),
      );
    },
  );
}
