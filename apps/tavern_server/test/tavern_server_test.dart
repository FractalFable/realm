import 'dart:convert';
import 'dart:io';

import 'package:relic/relic.dart';
import 'package:tavern_core/tavern_core.dart';
import 'package:tavern_server/tavern_server.dart';
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
    'tavern_server serves health, bootstrap, and tavern status without secrets',
    () async {
      final bootstrap = VenueBootstrap(
        branding: VenueBranding(
          name: 'Example Venue',
          primaryColorArgb: 0xFF6B2D5C,
        ),
        capabilities: const VenueCapabilities(
          onlineOrderingEnabled: true,
          aiAssistantEnabled: true,
        ),
      );
      final app = createTavernServerApp(bootstrap);
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
      expect(health.body['service'], 'tavern_server');

      final boot = await _getJson(client, server.port, '/api/v1/bootstrap');
      expect(boot.statusCode, 200);
      expect(VenueBootstrap.fromJson(boot.body), equals(bootstrap));

      final status = await _getJson(
        client,
        server.port,
        '/api/v1/tavern/status',
      );
      expect(status.statusCode, 200);
      expect(
        status.body,
        equals({
          'app': 'tavern',
          'onlineOrderingEnabled': true,
          'paymentsEnabled': false,
          'aiAssistantEnabled': true,
        }),
      );
    },
  );
}
