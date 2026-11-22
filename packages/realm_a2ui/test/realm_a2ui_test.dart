import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:realm_a2ui/realm_a2ui.dart';
import 'package:realm_core/realm_core.dart';
import 'package:realm_ui/realm_ui.dart';

void main() {
  final sampleMessages = <Map<String, Object?>>[
    {
      'version': '1.0',
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': RealmA2uiHost.basicCatalogId,
        'components': [
          {'id': 'root', 'component': 'Card', 'child': 'headline'},
          {'id': 'headline', 'component': 'Text', 'text': 'Live A2UI Summary'},
        ],
      },
    },
  ];

  testWidgets('gates gracefully when aiEnabled is false', (tester) async {
    final branding = AppBranding(
      name: 'Example Realm',
      primaryColorArgb: 0xFF6B2D5C,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRealmTheme(branding),
        home: Scaffold(
          body: RealmA2uiHost(
            aiEnabled: false,
            initialMessages: sampleMessages,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('realm_a2ui_disabled_card')), findsOne);
    expect(find.text('Live A2UI Summary'), findsNothing);
  });

  testWidgets('renders A2UI v1.0 surface under light and dark Realm themes', (
    tester,
  ) async {
    final first = AppBranding(
      name: 'Example Realm',
      primaryColorArgb: 0xFF6B2D5C,
    );
    final second = AppBranding(
      name: 'Second Realm',
      primaryColorArgb: 0xFF1B5E20,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildRealmTheme(first),
        home: Scaffold(
          body: RealmA2uiHost(aiEnabled: true, initialMessages: sampleMessages),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live A2UI Summary'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('realm_a2ui_surface_main')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildRealmTheme(second, brightness: .dark),
        home: Scaffold(
          body: RealmA2uiHost(aiEnabled: true, initialMessages: sampleMessages),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Live A2UI Summary'), findsOneWidget);

    // Unmount to verify processor/subscriptions dispose cleanly without error.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
