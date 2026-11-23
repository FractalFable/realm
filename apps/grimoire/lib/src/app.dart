import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grimoire_core/grimoire_core.dart';
import 'package:grimoire_notes/grimoire_notes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:realm_a2ui/realm_a2ui.dart';
import 'package:realm_core/realm_core.dart';
import 'package:realm_ui/realm_ui.dart';

/// Multi-platform Flutter shell for Grimoire E2EE interactive notes.
class GrimoireApp extends StatefulWidget {
  /// Creates a [GrimoireApp] configured from runtime [bootstrap].
  const GrimoireApp({
    super.key,
    this.bootstrap,
    this.themeMode = .system,
    this.vaultStore,
    this.scriptRuntime,
  });

  /// Runtime instance branding and capability flags.
  final AppBootstrap? bootstrap;

  /// Theme brightness mode used by [MaterialApp].
  final ThemeMode themeMode;

  /// Optional [LocalVaultStore] override for tests or platform persistence.
  final LocalVaultStore? vaultStore;

  /// Optional [ScriptRuntime] override for platform-specific JS engines.
  final ScriptRuntime? scriptRuntime;

  @override
  State<GrimoireApp> createState() => _GrimoireAppState();
}

class _GrimoireAppState extends State<GrimoireApp> {
  static final _sampleTime = DateTime.utc(2026, 11, 22, 12);
  static bool _debugExtensionRegistered = false;
  static _GrimoireAppState? _activeState;

  late final LocalVaultStore _vaultStore;
  late final ScriptRuntime _scriptRuntime;
  late final GrimoireWorkspaceCubit _cubit;

  @override
  void initState() {
    super.initState();
    _vaultStore = widget.vaultStore ?? _createStarterVault();
    _scriptRuntime =
        widget.scriptRuntime ??
        SandboxedScriptRuntime(a2uiCatalogId: RealmA2uiHost.basicCatalogId);
    _cubit = GrimoireWorkspaceCubit(
      vaultStore: _vaultStore,
      scriptRuntime: _scriptRuntime,
    );
    unawaited(_cubit.load());
    _activeState = this;
    _registerDebugExtension();
  }

  @override
  void dispose() {
    if (identical(_activeState, this)) {
      _activeState = null;
    }
    unawaited(_cubit.close());
    super.dispose();
  }

  AppBootstrap get _resolvedBootstrap =>
      widget.bootstrap ??
      AppBootstrap(
        branding: AppBranding(
          name: 'Example Grimoire',
          primaryColorArgb: 0xFF283593,
        ),
        capabilities: AppCapabilities(enabledModules: const {'grimoire'}),
      );

  static void _registerDebugExtension() {
    if (!kDebugMode || _debugExtensionRegistered) {
      return;
    }
    _debugExtensionRegistered = true;
    developer.registerExtension('ext.realm.getState', (_, _) async {
      final active = _activeState;
      if (active == null) {
        return developer.ServiceExtensionResponse.result(
          jsonEncode({'app': 'grimoire', 'mounted': false}),
        );
      }
      final state = active._cubit.state;
      final payload = switch (state) {
        GrimoireWorkspaceLoading() => {
          'app': 'grimoire',
          'brandingName': active._resolvedBootstrap.branding.name,
          'status': 'loading',
          'locked': false,
        },
        GrimoireWorkspaceLocked(:final noteCount) => {
          'app': 'grimoire',
          'brandingName': active._resolvedBootstrap.branding.name,
          'status': 'locked',
          'locked': true,
          'noteCount': noteCount,
        },
        GrimoireWorkspaceReady(
          :final notes,
          :final selectedNoteId,
          :final aiTrustTier,
        ) =>
          {
            'app': 'grimoire',
            'brandingName': active._resolvedBootstrap.branding.name,
            'status': 'ready',
            'locked': false,
            'selectedNoteId': selectedNoteId,
            'noteCount': notes.length,
            'aiTrustTier': aiTrustTier.name,
          },
        GrimoireWorkspaceFailure() => {
          'app': 'grimoire',
          'brandingName': active._resolvedBootstrap.branding.name,
          'status': 'failure',
          'locked': false,
        },
      };
      return developer.ServiceExtensionResponse.result(jsonEncode(payload));
    });
  }

  static LocalVaultStore _createStarterVault() => InMemoryVaultStore(
    initialNotes: [
      NoteDocument(
        id: 'vault-overview',
        title: 'Vault Architecture',
        createdAt: _sampleTime,
        updatedAt: _sampleTime.add(const Duration(minutes: 2)),
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
            text: 'Verify client-side AEAD and GraphRAG indexing',
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
            prompt: 'Render knowledge overview',
            cachedSurfaceJson: {
              'version': '1.0',
              'createSurface': {
                'surfaceId': 'main',
                'catalogId': RealmA2uiHost.basicCatalogId,
                'components': const [
                  {'id': 'root', 'component': 'Card', 'child': 'summary'},
                  {
                    'id': 'summary',
                    'component': 'Text',
                    'text': 'Local RAG A2UI Surface Ready',
                  },
                ],
              },
            },
          ),
        ],
      ),
      NoteDocument(
        id: 'script-playground',
        title: 'Interactive Script Guide',
        createdAt: _sampleTime,
        updatedAt: _sampleTime.add(const Duration(minutes: 1)),
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
    ],
  );

  @override
  Widget build(BuildContext context) {
    final bootstrap = _resolvedBootstrap;
    return BlocProvider<GrimoireWorkspaceCubit>.value(
      value: _cubit,
      child: MaterialApp(
        title: bootstrap.branding.name,
        theme: buildRealmTheme(bootstrap.branding),
        darkTheme: buildRealmTheme(bootstrap.branding, brightness: .dark),
        themeMode: widget.themeMode,
        home: GrimoireWorkspaceScreen(bootstrap: bootstrap),
      ),
    );
  }
}
