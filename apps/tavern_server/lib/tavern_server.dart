import 'package:realm_server_kit/realm_server_kit.dart';
import 'package:relic/relic.dart';
import 'package:tavern_core/tavern_core.dart';

/// Creates the Tavern [RelicApp] router using [bootstrap] for runtime venue
/// branding and capability flags.
RelicApp createTavernServerApp(VenueBootstrap bootstrap) => createRealmApp(
  RealmServerSpec(
    serviceName: 'tavern_server',
    bootstrapPayload: bootstrap.toJson,
  ),
  configureRoutes: (app) {
    app.get(
      '/api/v1/tavern/status',
      (_) => jsonOk({
        'app': 'tavern',
        'onlineOrderingEnabled': bootstrap.capabilities.onlineOrderingEnabled,
        'paymentsEnabled': bootstrap.capabilities.paymentsEnabled,
        'aiAssistantEnabled': bootstrap.capabilities.aiAssistantEnabled,
      }),
    );
  },
);
