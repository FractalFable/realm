import 'dart:async';
import 'dart:io';

import 'package:relic/relic.dart';
import 'package:tavern_core/tavern_core.dart';
import 'package:tavern_server/tavern_server.dart';

Future<void> main() async {
  final host = Platform.environment['HOST'] ?? '127.0.0.1';
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final venueName = Platform.environment['TAVERN_NAME'] ?? 'Example Venue';

  final bootstrap = VenueBootstrap(
    branding: VenueBranding(name: venueName, primaryColorArgb: 0xFF6B2D5C),
  );
  final app = createTavernServerApp(bootstrap);
  final address =
      (await InternetAddress.lookup(host)).firstOrNull ??
      InternetAddress.loopbackIPv4;
  final server = await app.serve(address: address, port: port);
  stdout.writeln(
    'tavern_server listening on ${address.address}:${server.port}',
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
