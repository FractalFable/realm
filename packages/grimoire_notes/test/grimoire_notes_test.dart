import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grimoire_core/grimoire_core.dart';
import 'package:grimoire_notes/grimoire_notes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:realm_a2ui/realm_a2ui.dart';
import 'package:realm_core/realm_core.dart';
import 'package:realm_ui/realm_ui.dart';

void main() {
  final sampleTime = DateTime.utc(2026, 11, 22, 12);

  List<NoteDocument> buildSampleNotes() => [
    NoteDocument(
      id: 'vault-overview',
      title: 'Vault Architecture',
      createdAt: sampleTime,
      updatedAt: sampleTime.add(const Duration(minutes: 2)),
      excludeFromCloudAi: true,
      tags: const {'e2ee', 'rag'},
      blocks: [
        RichTextBlock(
          id: 'b1',
          text: 'End-to-End Encrypted Knowledge Base',
          style: .heading2,
        ),
        RichTextBlock(
          id: 'b1-check',
          text: 'Audit AAD cipher bindings',
          style: .checklist,
          checked: false,
        ),
        NoteLinkBlock(
          id: 'b2',
          targetNoteId: 'script-playground',
          alias: 'Interactive Script Guide',
        ),
        WebEmbedBlock(
          id: 'b3',
          url: Uri(scheme: 'https', host: 'example.com', path: '/spec'),
          title: 'Reference Spec',
        ),
        ScriptBlock(
          id: 'b4',
          title: 'Summarize Linked Notes',
          source: 'return { linkedCount: 1 };',
          grantedPermissions: const {
            ScriptPermission.readCurrentNote,
            ScriptPermission.emitA2ui,
          },
        ),
        A2uiBlock(
          id: 'b5',
          surfaceId: 'main',
          prompt: 'Local RAG A2UI Surface Ready',
        ),
      ],
    ),
    NoteDocument(
      id: 'script-playground',
      title: 'Interactive Script Guide',
      createdAt: sampleTime,
      updatedAt: sampleTime.add(const Duration(minutes: 1)),
      tags: const {'scripts'},
      blocks: [
        RichTextBlock(
          id: 's1',
          text: 'Sandboxed JS runs locally with explicit capability grants.',
        ),
        NoteLinkBlock(
          id: 's2',
          targetNoteId: 'vault-overview',
          alias: 'Back to Vault Architecture',
        ),
      ],
    ),
  ];

  GrimoireWorkspaceCubit createCubit({List<NoteDocument>? notes}) =>
      GrimoireWorkspaceCubit(
        vaultStore: InMemoryVaultStore(
          initialNotes: notes ?? buildSampleNotes(),
          now: () => sampleTime.add(const Duration(minutes: 5)),
        ),
        scriptRuntime: SandboxedScriptRuntime(
          a2uiCatalogId: RealmA2uiHost.basicCatalogId,
        ),
        now: () => sampleTime.add(const Duration(minutes: 5)),
      );

  group('GrimoireWorkspaceCubit', () {
    test(
      'loads notes, creates note, and bumps revision on block edit',
      () async {
        final cubit = createCubit();
        addTearDown(cubit.close);

        await cubit.load();
        expect(cubit.state, isA<GrimoireWorkspaceReady>());
        final ready = cubit.state as GrimoireWorkspaceReady;
        expect(ready.activeNote?.id, 'vault-overview');
        expect(ready.activeBacklinks, {'script-playground'});

        await cubit.updateBlock(
          RichTextBlock(
            id: 'b1-check',
            text: 'Audit AAD cipher bindings',
            style: .checklist,
            checked: true,
          ),
        );
        final updatedState = cubit.state as GrimoireWorkspaceReady;
        expect(updatedState.activeNote?.revision, 1);
        final checkBlock = updatedState.activeNote!.blocks[1] as RichTextBlock;
        expect(checkBlock.checked, isTrue);

        await cubit.createNote(title: 'Field Notes', excludeFromCloudAi: true);
        final createdState = cubit.state as GrimoireWorkspaceReady;
        expect(createdState.notes.length, 3);
        expect(createdState.activeNote?.title, 'Field Notes');
        expect(createdState.activeNote?.excludeFromCloudAi, isTrue);
      },
    );

    test('filters search hits by AiTrustTier and executes scripts', () async {
      final cubit = createCubit();
      addTearDown(cubit.close);

      await cubit.load();
      cubit.updateSearchQuery('vault');
      var ready = cubit.state as GrimoireWorkspaceReady;
      expect(
        ready.searchHits.map((h) => h.note.id),
        contains('vault-overview'),
      );

      cubit.setAiTrustTier(AiTrustTier.optInByokCloud);
      ready = cubit.state as GrimoireWorkspaceReady;
      expect(
        ready.searchHits.map((h) => h.note.id),
        isNot(contains('vault-overview')),
      );

      await cubit.runScriptBlock(
        'b4',
        approvedPermissions: const {ScriptPermission.readCurrentNote},
      );
      ready = cubit.state as GrimoireWorkspaceReady;
      expect(ready.scriptResults['b4'], isA<ScriptErrorResult>());

      await cubit.runScriptBlock(
        'b4',
        approvedPermissions: const {
          ScriptPermission.readCurrentNote,
          ScriptPermission.emitA2ui,
        },
      );
      ready = cubit.state as GrimoireWorkspaceReady;
      expect(ready.scriptResults['b4'], isA<ScriptA2uiResult>());
    });

    test('locks vault and validates passphrase on unlock', () async {
      final cubit = createCubit();
      addTearDown(cubit.close);

      await cubit.load();
      cubit.lockVault();
      expect(cubit.state, const GrimoireWorkspaceLocked(noteCount: 2));

      await cubit.unlockVault(passphrase: '   ');
      expect(
        cubit.state,
        const GrimoireWorkspaceLocked(
          noteCount: 2,
          errorMessage: 'Passphrase is required to unlock the vault.',
        ),
      );

      await cubit.unlockVault(passphrase: 'correct-horse-battery');
      expect(cubit.state, isA<GrimoireWorkspaceReady>());
    });
  });

  group('GrimoireWorkspaceScreen widget & a11y', () {
    Widget buildHarness({
      required GrimoireWorkspaceCubit cubit,
      required AppBootstrap bootstrap,
      required ThemeMode themeMode,
    }) => BlocProvider<GrimoireWorkspaceCubit>.value(
      value: cubit,
      child: MaterialApp(
        title: bootstrap.branding.name,
        theme: buildRealmTheme(bootstrap.branding),
        darkTheme: buildRealmTheme(bootstrap.branding, brightness: .dark),
        themeMode: themeMode,
        home: GrimoireWorkspaceScreen(bootstrap: bootstrap),
      ),
    );

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

      final cubit1 = createCubit();
      addTearDown(cubit1.close);
      await cubit1.load();

      await tester.pumpWidget(
        buildHarness(cubit: cubit1, bootstrap: first, themeMode: .light),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('grimoire_scaffold')), findsOneWidget);
      expect(find.text('Example Grimoire'), findsOneWidget);
      expect(find.text('Local RAG A2UI Surface Ready'), findsOneWidget);
      final lightScheme = Theme.of(
        tester.element(find.byKey(const ValueKey('grimoire_scaffold'))),
      ).colorScheme;
      expect(lightScheme.brightness, Brightness.light);

      final cubit2 = createCubit();
      addTearDown(cubit2.close);
      await cubit2.load();

      await tester.pumpWidget(
        buildHarness(cubit: cubit2, bootstrap: second, themeMode: .dark),
      );
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
      'supports interactive blocks, RAG trust toggle, lock/unlock, and a11y',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final cubit = createCubit();
        addTearDown(cubit.close);
        await cubit.load();

        final bootstrap = AppBootstrap(
          branding: AppBranding(
            name: 'Example Grimoire',
            primaryColorArgb: 0xFF283593,
          ),
          capabilities: AppCapabilities(
            aiAssistantEnabled: true,
            enabledModules: const {'grimoire'},
          ),
        );

        try {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(
            buildHarness(cubit: cubit, bootstrap: bootstrap, themeMode: .light),
          );
          await tester.pumpAndSettle();

          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

          await tester.binding.setSurfaceSize(const Size(1280, 800));
          await tester.pumpAndSettle();

          // Toggle checklist block
          await tester.tap(
            find.byKey(const ValueKey('grimoire_checklist_b1-check')),
          );
          await tester.pumpAndSettle();
          expect(
            ((cubit.state as GrimoireWorkspaceReady).activeNote!.blocks[1]
                    as RichTextBlock)
                .checked,
            isTrue,
          );

          // Toggle web embed interactive mode
          await tester.tap(
            find.byKey(const ValueKey('grimoire_embed_toggle_b3')),
          );
          await tester.pumpAndSettle();
          expect(
            ((cubit.state as GrimoireWorkspaceReady).activeNote!.blocks[3]
                    as WebEmbedBlock)
                .allowInteractive,
            isTrue,
          );

          // Execute script block emitting A2UI
          await tester.tap(
            find.byKey(const ValueKey('grimoire_script_run_b4')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('realm_a2ui_surface_script_b4')),
            findsOneWidget,
          );

          // Navigate via NoteLinkBlock and back via backlink ActionChip
          await tester.tap(find.byKey(const ValueKey('grimoire_link_b2')));
          await tester.pumpAndSettle();
          expect(
            (cubit.state as GrimoireWorkspaceReady).activeNote?.id,
            'script-playground',
          );

          await tester.tap(
            find.byKey(const ValueKey('grimoire_backlink_vault-overview')),
          );
          await tester.pumpAndSettle();
          expect(
            (cubit.state as GrimoireWorkspaceReady).activeNote?.id,
            'vault-overview',
          );

          // Switch AI trust tier to BYOK cloud and confirm cloud-excluded note disappears from search list
          await tester.tap(
            find.byKey(const ValueKey('grimoire_trust_tier_toggle')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('grimoire_note_vault-overview')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('grimoire_note_script-playground')),
            findsOneWidget,
          );

          // Lock vault, verify blank passphrase validation, then unlock
          await tester.tap(find.byKey(const ValueKey('grimoire_lock_button')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('grimoire_locked_card')),
            findsOneWidget,
          );

          await tester.tap(
            find.byKey(const ValueKey('grimoire_unlock_button')),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('Passphrase is required to unlock the vault.'),
            findsOneWidget,
          );

          await tester.enterText(
            find.byKey(const ValueKey('grimoire_unlock_passphrase')),
            'realm-secret-passphrase',
          );
          await tester.tap(
            find.byKey(const ValueKey('grimoire_unlock_button')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('grimoire_active_note_title')),
            findsOneWidget,
          );

          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        } finally {
          await tester.binding.setSurfaceSize(null);
          semantics.dispose();
        }
      },
    );
  });
}
