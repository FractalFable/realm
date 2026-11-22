import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tavern_core/tavern_core.dart';
import 'package:tavern_guest/src/app.dart';

void main() {
  testWidgets('renders light and dark themes with two VenueBranding seeds', (
    tester,
  ) async {
    final first = VenueBootstrap(
      branding: VenueBranding(
        name: 'Example Venue',
        primaryColorArgb: 0xFF6B2D5C,
      ),
      capabilities: const VenueCapabilities(aiAssistantEnabled: true),
    );
    final second = VenueBootstrap(
      branding: VenueBranding(
        name: 'Second Venue',
        primaryColorArgb: 0xFF1B5E20,
      ),
    );

    await tester.pumpWidget(
      TavernGuestApp(bootstrap: first, themeMode: .light),
    );
    expect(find.byKey(const ValueKey('tavern_guest_scaffold')), findsOneWidget);
    expect(find.text('Example Venue'), findsOneWidget);
    final lightScheme = Theme.of(
      tester.element(find.byKey(const ValueKey('tavern_guest_scaffold'))),
    ).colorScheme;
    expect(lightScheme.brightness, Brightness.light);

    await tester.pumpWidget(
      TavernGuestApp(bootstrap: second, themeMode: .dark),
    );
    await tester.pumpAndSettle();
    expect(find.text('Second Venue'), findsOneWidget);
    final darkScheme = Theme.of(
      tester.element(find.byKey(const ValueKey('tavern_guest_scaffold'))),
    ).colorScheme;
    expect(darkScheme.brightness, Brightness.dark);
    expect(darkScheme.primary, isNot(equals(lightScheme.primary)));
  });

  testWidgets(
    'supports compact and expanded viewports, interactions, and a11y',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.binding.setSurfaceSize(const Size(390, 844));

        await tester.pumpWidget(const TavernGuestApp(themeMode: .light));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.tap(
          find.byKey(const ValueKey('tavern_guest_add_item_button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Items in cart: 1'), findsOneWidget);

        await tester.binding.setSurfaceSize(const Size(1280, 800));
        await tester.pumpAndSettle();
        expect(find.text('Items in cart: 1'), findsOneWidget);
      } finally {
        await tester.binding.setSurfaceSize(null);
        semantics.dispose();
      }
    },
  );
}
