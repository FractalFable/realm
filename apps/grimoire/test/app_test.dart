import 'package:flutter_test/flutter_test.dart';
import 'package:grimoire/src/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:realm_core/realm_core.dart';

void main() {
  testWidgets('renders light and dark themes with two AppBranding seeds', (
    tester,
  ) async {
    final first = AppBootstrap(
      branding: AppBranding(
        name: 'Example Grimoire',
        primaryColorArgb: 0xFF283593,
      ),
      capabilities: AppCapabilities(
        aiAssistantEnabled: true,
        enabledModules: const {'grimoire'},
      ),
    );
    final second = AppBootstrap(
      branding: AppBranding(
        name: 'Second Grimoire',
        primaryColorArgb: 0xFF1B5E20,
      ),
    );

    await tester.pumpWidget(GrimoireApp(bootstrap: first, themeMode: .light));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('grimoire_scaffold')), findsOneWidget);
    expect(find.text('Example Grimoire'), findsOneWidget);
    expect(find.text('Local RAG A2UI Surface Ready'), findsOneWidget);
    final lightScheme = Theme.of(
      tester.element(find.byKey(const ValueKey('grimoire_scaffold'))),
    ).colorScheme;
    expect(lightScheme.brightness, Brightness.light);

    await tester.pumpWidget(GrimoireApp(bootstrap: second, themeMode: .dark));
    await tester.pumpAndSettle();

    expect(find.text('Second Grimoire'), findsOneWidget);
    expect(find.byKey(const ValueKey('realm_a2ui_disabled_card')), findsOne);
    final darkScheme = Theme.of(
      tester.element(find.byKey(const ValueKey('grimoire_scaffold'))),
    ).colorScheme;
    expect(darkScheme.brightness, Brightness.dark);
    expect(darkScheme.primary, isNot(equals(lightScheme.primary)));
  });

  testWidgets(
    'supports compact/expanded viewports, note switching, scripts, lock, and a11y',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(
          GrimoireApp(
            bootstrap: AppBootstrap(
              branding: AppBranding(
                name: 'Example Grimoire',
                primaryColorArgb: 0xFF283593,
              ),
              capabilities: AppCapabilities(
                aiAssistantEnabled: true,
                enabledModules: const {'grimoire'},
              ),
            ),
            themeMode: .light,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Backlinks: 1'), findsOneWidget);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.binding.setSurfaceSize(const Size(1280, 800));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('grimoire_script_run_b4')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('realm_a2ui_surface_script_b4')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('grimoire_note_script-playground')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('grimoire_active_note_title')),
          findsOneWidget,
        );
        expect(find.text('Backlinks: 1'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('grimoire_lock_button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('grimoire_locked_card')),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const ValueKey('grimoire_unlock_passphrase')),
          'grimoire-passphrase',
        );
        await tester.tap(find.byKey(const ValueKey('grimoire_unlock_button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('grimoire_active_note_title')),
          findsOneWidget,
        );
      } finally {
        await tester.binding.setSurfaceSize(null);
        semantics.dispose();
      }
    },
  );
}
