import 'package:meta/meta.dart';
import 'package:relic/relic.dart';

import 'json_response.dart';

/// App-neutral server specification for creating a Realm [RelicApp].
@immutable
class RealmServerSpec({
  required final String serviceName,
  required final Map<String, Object?> Function() bootstrapPayload,
}) {
  this {
    if (serviceName.trim().isEmpty) {
      throw ArgumentError.value(
        serviceName,
        'serviceName',
        'Service name must not be empty.',
      );
    }
  }
}

/// Builds a [RelicApp] pre-wired with standard `/health` and
/// `/api/v1/bootstrap` routes, plus optional app-specific [configureRoutes].
RelicApp createRealmApp(
  RealmServerSpec spec, {
  void Function(RelicApp app)? configureRoutes,
}) {
  final app = RelicApp()
    ..get(
      '/health',
      (_) => jsonOk({'status': 'ok', 'service': spec.serviceName}),
    )
    ..get('/api/v1/bootstrap', (_) => jsonOk(spec.bootstrapPayload()));

  configureRoutes?.call(app);
  return app;
}
