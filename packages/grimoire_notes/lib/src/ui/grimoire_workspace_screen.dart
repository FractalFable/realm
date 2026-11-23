import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grimoire_core/grimoire_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:realm_a2ui/realm_a2ui.dart';
import 'package:realm_core/realm_core.dart';

import '../cubit/grimoire_workspace_cubit.dart';

/// Responsive, white-label workspace screen for Grimoire E2EE interactive
/// notes.
class GrimoireWorkspaceScreen extends StatefulWidget {
  /// Creates a [GrimoireWorkspaceScreen] using [bootstrap] branding and
  /// capabilities.
  const GrimoireWorkspaceScreen({super.key, required this.bootstrap});

  /// Runtime instance branding and capability flags.
  final AppBootstrap bootstrap;

  @override
  State<GrimoireWorkspaceScreen> createState() =>
      _GrimoireWorkspaceScreenState();
}

class _GrimoireWorkspaceScreenState extends State<GrimoireWorkspaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GrimoireWorkspaceCubit>();
    return BlocBuilder<GrimoireWorkspaceCubit, GrimoireWorkspaceState>(
      builder: (context, state) {
        final trustTier = state is GrimoireWorkspaceReady
            ? state.aiTrustTier
            : AiTrustTier.strictLocal;

        return Scaffold(
          key: const ValueKey('grimoire_scaffold'),
          appBar: AppBar(
            title: Text(
              widget.bootstrap.branding.name,
              key: const ValueKey('grimoire_title'),
            ),
            actions: [
              if (state is GrimoireWorkspaceReady)
                Semantics(
                  identifier: 'grimoire_trust_tier_toggle',
                  label: trustTier == AiTrustTier.strictLocal
                      ? 'Strict local AI privacy tier'
                      : 'Opt-in BYOK cloud AI tier',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('grimoire_trust_tier_toggle'),
                    tooltip: trustTier == AiTrustTier.strictLocal
                        ? 'AI Tier: Strict Local (tap to switch)'
                        : 'AI Tier: BYOK Cloud Opt-In (tap to switch)',
                    icon: Icon(
                      trustTier == AiTrustTier.strictLocal
                          ? Icons.shield_outlined
                          : Icons.cloud_outlined,
                    ),
                    onPressed: () {
                      final next = trustTier == AiTrustTier.strictLocal
                          ? AiTrustTier.optInByokCloud
                          : AiTrustTier.strictLocal;
                      cubit.setAiTrustTier(next);
                    },
                  ),
                ),
              if (state is GrimoireWorkspaceReady)
                Semantics(
                  identifier: 'grimoire_lock_button',
                  label: 'Lock encrypted vault',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('grimoire_lock_button'),
                    tooltip: 'Lock vault',
                    icon: const Icon(Icons.lock_outline),
                    onPressed: () {
                      _passphraseController.clear();
                      cubit.lockVault();
                    },
                  ),
                ),
            ],
          ),
          body: switch (state) {
            GrimoireWorkspaceLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            GrimoireWorkspaceFailure(:final message) => Center(
              child: Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      Text(message),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => unawaited(cubit.load()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GrimoireWorkspaceLocked() => _LockedVaultView(
              state: state,
              passphraseController: _passphraseController,
              onUnlock: () => unawaited(
                cubit.unlockVault(passphrase: _passphraseController.text),
              ),
            ),
            GrimoireWorkspaceReady() => _ReadyWorkspaceView(
              state: state,
              bootstrap: widget.bootstrap,
              searchController: _searchController,
              onSearchChanged: cubit.updateSearchQuery,
              onSelectNote: cubit.selectNote,
              onCreateNote: () => unawaited(_showCreateNoteDialog(context)),
              onToggleCloudAi: () =>
                  unawaited(cubit.toggleExcludeFromCloudAi()),
              onAddBlock: (block) => unawaited(cubit.addBlock(block)),
              onUpdateBlock: (block) => unawaited(cubit.updateBlock(block)),
              onRunScript: (blockId, permissions) => unawaited(
                cubit.runScriptBlock(blockId, approvedPermissions: permissions),
              ),
            ),
          },
        );
      },
    );
  }

  Future<void> _showCreateNoteDialog(BuildContext context) async {
    final cubit = context.read<GrimoireWorkspaceCubit>();
    final result = await showDialog<({String title, bool excludeFromCloudAi})>(
      context: context,
      builder: (_) => const _CreateNoteDialog(),
    );
    if (result != null && mounted) {
      await cubit.createNote(
        title: result.title,
        excludeFromCloudAi: result.excludeFromCloudAi,
      );
    }
  }
}

class _CreateNoteDialog extends StatefulWidget {
  const _CreateNoteDialog();

  @override
  State<_CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<_CreateNoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  bool _excludeFromCloudAi = true;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create Encrypted Note'),
    content: Column(
      mainAxisSize: .min,
      children: [
        TextField(
          key: const ValueKey('grimoire_new_note_title'),
          controller: _titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Note title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          key: const ValueKey('grimoire_new_note_exclude_cloud'),
          title: const Text('Local-only AI lock'),
          subtitle: const Text('Exclude note from BYOK cloud RAG context'),
          value: _excludeFromCloudAi,
          onChanged: (value) => setState(() => _excludeFromCloudAi = value),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('grimoire_new_note_submit'),
        onPressed: () {
          final title = _titleController.text.trim();
          if (title.isEmpty) {
            return;
          }
          Navigator.of(context)
              .pop((title: title, excludeFromCloudAi: _excludeFromCloudAi));
        },
        child: const Text('Create'),
      ),
    ],
  );
}

class _LockedVaultView extends StatelessWidget {
  const _LockedVaultView({
    required this.state,
    required this.passphraseController,
    required this.onUnlock,
  });

  final GrimoireWorkspaceLocked state;
  final TextEditingController passphraseController;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card.outlined(
          key: const ValueKey('grimoire_locked_card'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                const Icon(Icons.lock_outline, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Vault Locked',
                  textAlign: .center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.noteCount} encrypted notes protected locally.',
                  textAlign: .center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('grimoire_unlock_passphrase'),
                  controller: passphraseController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Vault passphrase',
                    border: const OutlineInputBorder(),
                    errorText: state.errorMessage,
                  ),
                  onSubmitted: (_) => onUnlock(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('grimoire_unlock_button'),
                  onPressed: onUnlock,
                  child: const Text('Unlock Vault'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ReadyWorkspaceView extends StatelessWidget {
  const _ReadyWorkspaceView({
    required this.state,
    required this.bootstrap,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSelectNote,
    required this.onCreateNote,
    required this.onToggleCloudAi,
    required this.onAddBlock,
    required this.onUpdateBlock,
    required this.onRunScript,
  });

  final GrimoireWorkspaceReady state;
  final AppBootstrap bootstrap;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSelectNote;
  final VoidCallback onCreateNote;
  final VoidCallback onToggleCloudAi;
  final ValueChanged<NoteBlock> onAddBlock;
  final ValueChanged<NoteBlock> onUpdateBlock;
  final void Function(String blockId, Set<ScriptPermission> permissions)
  onRunScript;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 900;
      final sidebar = _VaultSidebar(
        state: state,
        searchController: searchController,
        onSearchChanged: onSearchChanged,
        onSelectNote: onSelectNote,
        onCreateNote: onCreateNote,
      );
      final workspace = _NoteWorkspacePane(
        state: state,
        aiEnabled: bootstrap.capabilities.aiAssistantEnabled,
        onSelectNote: onSelectNote,
        onToggleCloudAi: onToggleCloudAi,
        onAddBlock: onAddBlock,
        onUpdateBlock: onUpdateBlock,
        onRunScript: onRunScript,
      );

      return Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
                crossAxisAlignment: .start,
                children: [
                  SizedBox(
                    width: 280,
                    child: SingleChildScrollView(child: sidebar),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: SingleChildScrollView(child: workspace)),
                ],
              )
            : ListView(
                children: [sidebar, const SizedBox(height: 16), workspace],
              ),
      );
    },
  );
}

class _VaultSidebar extends StatelessWidget {
  const _VaultSidebar({
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSelectNote,
    required this.onCreateNote,
  });

  final GrimoireWorkspaceReady state;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSelectNote;
  final VoidCallback onCreateNote;

  @override
  Widget build(BuildContext context) {
    final activeId = state.activeNote?.id ?? '';
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        TextField(
          key: const ValueKey('grimoire_search_field'),
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search notes (local RAG)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: const ValueKey('grimoire_new_note_button'),
          icon: const Icon(Icons.note_add_outlined),
          label: const Text('New Note'),
          onPressed: onCreateNote,
        ),
        const SizedBox(height: 10),
        Card.outlined(
          child: state.searchHits.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No notes match this query and AI trust tier.'),
                )
              : Column(
                  mainAxisSize: .min,
                  children: [
                    for (final hit in state.searchHits)
                      ListTile(
                        key: ValueKey('grimoire_note_${hit.note.id}'),
                        selected: hit.note.id == activeId,
                        leading: Icon(
                          hit.note.excludeFromCloudAi
                              ? Icons.shield_outlined
                              : Icons.note_alt_outlined,
                        ),
                        title: Text(hit.note.title),
                        subtitle: Text(
                          '${hit.note.blocks.length} blocks'
                          '${hit.graphNeighborIds.isEmpty ? '' : ' • ${hit.graphNeighborIds.length} linked'}',
                        ),
                        onTap: () => onSelectNote(hit.note.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _NoteWorkspacePane extends StatelessWidget {
  const _NoteWorkspacePane({
    required this.state,
    required this.aiEnabled,
    required this.onSelectNote,
    required this.onToggleCloudAi,
    required this.onAddBlock,
    required this.onUpdateBlock,
    required this.onRunScript,
  });

  final GrimoireWorkspaceReady state;
  final bool aiEnabled;
  final ValueChanged<String> onSelectNote;
  final VoidCallback onToggleCloudAi;
  final ValueChanged<NoteBlock> onAddBlock;
  final ValueChanged<NoteBlock> onUpdateBlock;
  final void Function(String blockId, Set<ScriptPermission> permissions)
  onRunScript;

  @override
  Widget build(BuildContext context) {
    final note = state.activeNote;
    if (note == null) {
      return const Card.outlined(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Your encrypted vault is empty. Create a note to begin.'),
        ),
      );
    }

    final backlinks = state.activeBacklinks;
    final titlesById = {for (final n in state.notes) n.id: n.title};

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        if (state.statusMessage case final message?) ...[
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(message),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
            FilterChip(
              key: const ValueKey('grimoire_cloud_ai_chip'),
              selected: note.excludeFromCloudAi,
              label: Text(
                note.excludeFromCloudAi
                    ? 'Local-only AI lock'
                    : 'Standard E2EE note',
              ),
              onSelected: (_) => onToggleCloudAi(),
            ),
            Chip(
              key: const ValueKey('grimoire_backlinks_chip'),
              label: Text('Backlinks: ${backlinks.length}'),
            ),
            for (final tag in note.tags) Chip(label: Text('#$tag')),
          ],
        ),
        if (backlinks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final backlinkId in backlinks)
                ActionChip(
                  key: ValueKey('grimoire_backlink_$backlinkId'),
                  avatar: const Icon(Icons.link, size: 18),
                  label: Text('From: ${titlesById[backlinkId] ?? backlinkId}'),
                  onPressed: () => onSelectNote(backlinkId),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        for (final block in note.blocks) ...[
          _buildBlockWidget(context, note, block, titlesById),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              key: const ValueKey('grimoire_add_text_block'),
              icon: const Icon(Icons.notes),
              label: const Text('Add Note Block'),
              onPressed: () {
                final nextId = _nextBlockId(note, 'note');
                onAddBlock(
                  RichTextBlock(
                    id: nextId,
                    text: 'Encrypted note block ${note.blocks.length + 1}.',
                  ),
                );
              },
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('grimoire_add_checklist_block'),
              icon: const Icon(Icons.check_box_outlined),
              label: const Text('Add Checklist'),
              onPressed: () {
                final nextId = _nextBlockId(note, 'todo');
                onAddBlock(
                  RichTextBlock(
                    id: nextId,
                    text: 'Checklist task ${note.blocks.length + 1}',
                    style: .checklist,
                    checked: false,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlockWidget(
    BuildContext context,
    NoteDocument note,
    NoteBlock block,
    Map<String, String> titlesById,
  ) => switch (block) {
    RichTextBlock() => _RichTextBlockCard(
      block: block,
      onToggleChecked: (checked) => onUpdateBlock(
        RichTextBlock(
          id: block.id,
          text: block.text,
          style: block.style,
          checked: checked,
        ),
      ),
    ),
    NoteLinkBlock() => Card.outlined(
      child: ListTile(
        key: ValueKey('grimoire_link_${block.id}'),
        leading: const Icon(Icons.call_made),
        title: Text(
          block.alias ?? titlesById[block.targetNoteId] ?? block.targetNoteId,
        ),
        subtitle: Text('Linked note: ${block.targetNoteId}'),
        onTap: () => onSelectNote(block.targetNoteId),
      ),
    ),
    WebEmbedBlock() => Card.outlined(
      key: ValueKey('grimoire_embed_${block.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                const Icon(Icons.public, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.title ?? block.url.host,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sandboxed HTTPS embed (${block.url.host}) — zero vault key access.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SwitchListTile(
              key: ValueKey('grimoire_embed_toggle_${block.id}'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow interactive embed'),
              value: block.allowInteractive,
              onChanged: (allow) => onUpdateBlock(
                WebEmbedBlock(
                  id: block.id,
                  url: block.url,
                  title: block.title,
                  allowInteractive: allow,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    ScriptBlock() => _ScriptBlockCard(
      block: block,
      aiEnabled: aiEnabled,
      result: state.scriptResults[block.id],
      onRun: (approved) => onRunScript(block.id, approved),
    ),
    A2uiBlock() => RealmA2uiHost(
      aiEnabled: aiEnabled,
      surfaceId: block.surfaceId,
      initialMessages: [
        block.cachedSurfaceJson ??
            {
              'version': '1.0',
              'createSurface': {
                'surfaceId': block.surfaceId,
                'catalogId': RealmA2uiHost.basicCatalogId,
                'components': [
                  {'id': 'root', 'component': 'Card', 'child': 'summary'},
                  {
                    'id': 'summary',
                    'component': 'Text',
                    'text': block.prompt ?? 'Local RAG A2UI Surface Ready',
                  },
                ],
              },
            },
      ],
    ),
  };

  String _nextBlockId(NoteDocument note, String prefix) {
    final existing = {for (final b in note.blocks) b.id};
    var idx = note.blocks.length + 1;
    var candidate = '$prefix-$idx';
    while (existing.contains(candidate)) {
      idx++;
      candidate = '$prefix-$idx';
    }
    return candidate;
  }
}

class _RichTextBlockCard extends StatelessWidget {
  const _RichTextBlockCard({
    required this.block,
    required this.onToggleChecked,
  });

  final RichTextBlock block;
  final ValueChanged<bool> onToggleChecked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (block.style == RichTextStyle.checklist) {
      return Card.outlined(
        child: CheckboxListTile(
          key: ValueKey('grimoire_checklist_${block.id}'),
          title: Text(block.text),
          value: block.checked ?? false,
          onChanged: (value) => onToggleChecked(value ?? false),
        ),
      );
    }

    final textStyle = switch (block.style) {
      RichTextStyle.heading1 => theme.textTheme.headlineMedium,
      RichTextStyle.heading2 => theme.textTheme.titleLarge,
      RichTextStyle.heading3 => theme.textTheme.titleMedium,
      RichTextStyle.quote => theme.textTheme.bodyLarge?.copyWith(
        fontStyle: .italic,
      ),
      RichTextStyle.code => theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
      ),
      RichTextStyle.paragraph ||
      RichTextStyle.checklist => theme.textTheme.bodyLarge,
    };

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: double.infinity,
          child: Text(block.text, style: textStyle),
        ),
      ),
    );
  }
}

class _ScriptBlockCard extends StatefulWidget {
  const _ScriptBlockCard({
    required this.block,
    required this.aiEnabled,
    required this.result,
    required this.onRun,
  });

  final ScriptBlock block;
  final bool aiEnabled;
  final ScriptExecutionResult? result;
  final ValueChanged<Set<ScriptPermission>> onRun;

  @override
  State<_ScriptBlockCard> createState() => _ScriptBlockCardState();
}

class _ScriptBlockCardState extends State<_ScriptBlockCard> {
  late Set<ScriptPermission> _approved = Set.of(
    widget.block.grantedPermissions,
  );

  @override
  void didUpdateWidget(_ScriptBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id ||
        oldWidget.block.grantedPermissions != widget.block.grantedPermissions) {
      _approved = Set.of(widget.block.grantedPermissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;

    return Card.outlined(
      key: ValueKey('grimoire_script_${widget.block.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.block.title ?? 'Sandboxed Script'} '
                    '(${widget.block.language.name})',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  key: ValueKey('grimoire_script_run_${widget.block.id}'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run'),
                  onPressed: () => widget.onRun(Set.unmodifiable(_approved)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.block.source,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final permission in ScriptPermission.values)
                  FilterChip(
                    key: ValueKey(
                      'grimoire_script_perm_${widget.block.id}_${permission.name}',
                    ),
                    selected: _approved.contains(permission),
                    label: Text(permission.name),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _approved.add(permission);
                        } else {
                          _approved.remove(permission);
                        }
                      });
                    },
                  ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 12),
              switch (result) {
                ScriptValueResult(:final summary, :final data) => Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(summary, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      data.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                ScriptA2uiResult(:final surfaceId, :final messages) =>
                  RealmA2uiHost(
                    aiEnabled: widget.aiEnabled,
                    surfaceId: surfaceId,
                    initialMessages: messages,
                  ),
                ScriptErrorResult(:final message) => Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              },
            ],
          ],
        ),
      ),
    );
  }
}
