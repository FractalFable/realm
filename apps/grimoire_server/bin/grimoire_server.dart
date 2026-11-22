import 'dart:async';
import 'dart:io';

import 'package:grimoire_server/grimoire_server.dart';
import 'package:realm_core/realm_core.dart';
import 'package:relic/relic.dart';

Future<void> main() async {
  final host = Platform.environment['HOST'] ?? '127.0.0.1';
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8081;
  final appName = Platform.environment['GRIMOIRE_NAME'] ?? 'Example Grimoire';

  final bootstrap = AppBootstrap(
    branding: AppBranding(name: appName, primaryColorArgb: 0xFF283593),
    capabilities: AppCapabilities(enabledModules: const {'grimoire'}),
  );
  final app = createGrimoireServerApp(bootstrap);
  final address =
      (await InternetAddress.lookup(host)).firstOrNull ??
      InternetAddress.loopbackIPv4;
  final server = await app.serve(address: address, port: port);
  stdout.writeln(
    'grimoire_server listening on ${address.address}:${server.port}',
  );

  final shutdown = Completer<void>();
  final subs = <StreamSubscription<ProcessSignal>>[
    ProcessSignal.sigint.watch().listen((_) {
      if (!shutdown.isCompleted) {
        shutdown.complete();
      }
    }),
    if (!Platform.isWindows)
      ProcessSignal.sigterm.watch().listen((_) {
        if (!shutdown.isCompleted) {
          shutdown.complete();
        }
      }),
  ];

  await shutdown.future;
  for (final sub in subs) {
    await sub.cancel();
  }
  await app.close();
}
