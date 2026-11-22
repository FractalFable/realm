import 'package:grimoire_core/grimoire_core.dart';
import 'package:realm_core/realm_core.dart';
import 'package:realm_server_kit/realm_server_kit.dart';
import 'package:relic/relic.dart';

/// Creates the Grimoire [RelicApp] router using [bootstrap] for runtime
/// branding and capability flags.
RelicApp createGrimoireServerApp(AppBootstrap bootstrap) => createRealmApp(
  RealmServerSpec(
    serviceName: 'grimoire_server',
    bootstrapPayload: bootstrap.toJson,
  ),
  configureRoutes: (app) {
    app.get(
      '/api/v1/grimoire/status',
      (_) => jsonOk({
        'app': 'grimoire',
        'zeroKnowledgeSync': true,
        'aiAssistantEnabled': bootstrap.capabilities.aiAssistantEnabled,
        'supportedCiphers': [
          for (final suite in CipherSuite.values) suite.name,
        ],
      }),
    );
  },
);
