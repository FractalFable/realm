import 'package:grimoire_core/grimoire_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:realm_a2ui/realm_a2ui.dart';
import 'package:realm_core/realm_core.dart';
import 'package:realm_ui/realm_ui.dart';

/// Multi-platform Flutter shell for Grimoire E2EE interactive notes.
class GrimoireApp extends StatefulWidget {
  /// Creates a [GrimoireApp] configured from runtime [bootstrap].
  const GrimoireApp({super.key, this.bootstrap, this.themeMode = .system});

  /// Runtime instance branding and capability flags.
  final AppBootstrap? bootstrap;

  /// Theme brightness mode used by [MaterialApp].
  final ThemeMode themeMode;

  @override
  State<GrimoireApp> createState() => _GrimoireAppState();
}

class _GrimoireAppState extends State<GrimoireApp> {
  static final _sampleTime = DateTime.utc(2026, 11, 22, 12);

  late final List<NoteDocument> _notes = [
    NoteDocument(
      id: 'vault-overview',
      title: 'Vault Architecture',
      createdAt: _sampleTime,
      updatedAt: _sampleTime,
      excludeFromCloudAi: true,
      tags: const {'e2ee', 'rag'},
      blocks: [
        RichTextBlock(
          id: 'b1',
          text: 'End-to-End Encrypted Knowledge Base',
          style: .heading2,
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
        ),
      ],
    ),
    NoteDocument(
      id: 'script-playground',
      title: 'Interactive Script Guide',
      createdAt: _sampleTime,
      updatedAt: _sampleTime,
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

  late final NoteGraph _graph = NoteGraph(_notes);
  String _selectedNoteId = 'vault-overview';

  @override
  Widget build(BuildContext context) {
    final bootstrap =
        widget.bootstrap ??
        AppBootstrap(
          branding: AppBranding(
            name: 'Example Grimoire',
            primaryColorArgb: 0xFF283593,
          ),
          capabilities: AppCapabilities(enabledModules: const {'grimoire'}),
        );
    final activeNote = _notes.firstWhere(
      (note) => note.id == _selectedNoteId,
      orElse: () => _notes.first,
    );
    final backlinks = _graph.backlinksFor(activeNote.id);

    return MaterialApp(
      title: bootstrap.branding.name,
      theme: buildRealmTheme(bootstrap.branding),
      darkTheme: buildRealmTheme(bootstrap.branding, brightness: .dark),
      themeMode: widget.themeMode,
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return Scaffold(
            key: const ValueKey('grimoire_scaffold'),
            appBar: AppBar(
              title: Text(
                bootstrap.branding.name,
                key: const ValueKey('grimoire_title'),
              ),
              actions: [
                Semantics(
                  identifier: 'grimoire_lock_button',
                  label: 'Lock encrypted vault',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('grimoire_lock_button'),
                    tooltip: 'Lock vault',
                    icon: const Icon(Icons.lock_outline),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(
                      crossAxisAlignment: .start,
                      children: [
                        SizedBox(
                          width: 260,
                          child: _NoteList(
                            notes: _notes,
                            selectedNoteId: activeNote.id,
                            onSelect: (id) =>
                                setState(() => _selectedNoteId = id),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _NoteWorkspace(
                            note: activeNote,
                            backlinks: backlinks,
                            aiEnabled:
                                bootstrap.capabilities.aiAssistantEnabled,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        _NoteList(
                          notes: _notes,
                          selectedNoteId: activeNote.id,
                          onSelect: (id) =>
                              setState(() => _selectedNoteId = id),
                        ),
                        const SizedBox(height: 16),
                        _NoteWorkspace(
                          note: activeNote,
                          backlinks: backlinks,
                          aiEnabled: bootstrap.capabilities.aiAssistantEnabled,
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _NoteList extends StatelessWidget {
  const _NoteList({
    required this.notes,
    required this.selectedNoteId,
    required this.onSelect,
  });

  final List<NoteDocument> notes;
  final String selectedNoteId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Column(
      mainAxisSize: .min,
      children: [
        for (final note in notes)
          ListTile(
            key: ValueKey('grimoire_note_${note.id}'),
            selected: note.id == selectedNoteId,
            leading: Icon(
              note.excludeFromCloudAi ? Icons.shield_outlined : Icons.note_alt,
            ),
            title: Text(note.title),
            subtitle: Text('${note.blocks.length} blocks'),
            onTap: () => onSelect(note.id),
          ),
      ],
    ),
  );
}

class _NoteWorkspace extends StatelessWidget {
  const _NoteWorkspace({
    required this.note,
    required this.backlinks,
    required this.aiEnabled,
  });

  final NoteDocument note;
  final Set<String> backlinks;
  final bool aiEnabled;

  static final _a2uiMessages = <Map<String, Object?>>[
    {
      'version': '1.0',
      'createSurface': {
        'surfaceId': 'main',
        'catalogId': RealmA2uiHost.basicCatalogId,
        'components': [
          {'id': 'root', 'component': 'Card', 'child': 'summary'},
          {
            'id': 'summary',
            'component': 'Text',
            'text': 'Local RAG A2UI Surface Ready',
          },
        ],
      },
    },
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    mainAxisSize: .min,
    children: [
      Text(
        note.title,
        key: const ValueKey('grimoire_active_note_title'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(
            label: Text(
              note.excludeFromCloudAi
                  ? 'Local-only AI lock'
                  : 'Standard E2EE note',
            ),
          ),
          Chip(
            key: const ValueKey('grimoire_backlinks_chip'),
            label: Text('Backlinks: ${backlinks.length}'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              for (final block in note.blocks) ...[
                Text('[${block.type}] ${_describeBlock(block)}'),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      RealmA2uiHost(aiEnabled: aiEnabled, initialMessages: _a2uiMessages),
    ],
  );

  String _describeBlock(NoteBlock block) => switch (block) {
    RichTextBlock(:final text) => text,
    NoteLinkBlock(:final alias, :final targetNoteId) => alias ?? targetNoteId,
    WebEmbedBlock(:final title, :final url) => title ?? url.host,
    ScriptBlock(:final title, :final language) =>
      '${title ?? "Script"} (${language.name})',
    A2uiBlock(:final surfaceId) => 'Surface: $surfaceId',
  };
}
