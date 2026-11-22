import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tavern_core/tavern_core.dart';
import 'package:tavern_staff/src/app.dart';

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
      TavernStaffApp(bootstrap: first, themeMode: .light),
    );
    expect(find.byKey(const ValueKey('tavern_staff_scaffold')), findsOneWidget);
    expect(find.text('Example Venue — Staff'), findsOneWidget);
    final lightScheme = Theme.of(
      tester.element(find.byKey(const ValueKey('tavern_staff_scaffold'))),
    ).colorScheme;
    expect(lightScheme.brightness, Brightness.light);

    await tester.pumpWidget(
      TavernStaffApp(bootstrap: second, themeMode: .dark),
    );
    await tester.pumpAndSettle();
    expect(find.text('Second Venue — Staff'), findsOneWidget);
    final darkScheme = Theme.of(
      tester.element(find.byKey(const ValueKey('tavern_staff_scaffold'))),
    ).colorScheme;
    expect(darkScheme.brightness, Brightness.dark);
    expect(darkScheme.primary, isNot(equals(lightScheme.primary)));
  });

  testWidgets('adapts between compact and expanded viewports and meets a11y', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(const TavernStaffApp(themeMode: .light));
      expect(
        find.byKey(const ValueKey('tavern_staff_nav_bar')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('tavern_staff_rail')), findsNothing);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tavern_staff_rail')), findsOneWidget);
      expect(find.byKey(const ValueKey('tavern_staff_nav_bar')), findsNothing);

      await tester.tap(find.text('Bills'));
      await tester.pumpAndSettle();
      expect(find.text('Bills'), findsAtLeastNWidgets(2));
    } finally {
      await tester.binding.setSurfaceSize(null);
      semantics.dispose();
    }
  });
}
