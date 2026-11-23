import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grimoire_core/grimoire_core.dart';
import 'package:meta/meta.dart';

/// Sealed UI state for [GrimoireWorkspaceCubit].
@immutable
sealed class GrimoireWorkspaceState {
  const GrimoireWorkspaceState();
}

/// Initial loading state while vault notes are fetched.
@immutable
final class GrimoireWorkspaceLoading extends GrimoireWorkspaceState {
  /// Creates a [GrimoireWorkspaceLoading] state.
  const GrimoireWorkspaceLoading();

  @override
  bool operator ==(Object other) => other is GrimoireWorkspaceLoading;

  @override
  int get hashCode => (GrimoireWorkspaceLoading).hashCode;
}

/// Session-locked state requiring a non-empty passphrase to resume.
@immutable
final class GrimoireWorkspaceLocked extends GrimoireWorkspaceState {
  /// Creates a [GrimoireWorkspaceLocked] state.
  const GrimoireWorkspaceLocked({required this.noteCount, this.errorMessage});

  /// Count of notes held in the locked vault.
  final int noteCount;

  /// Optional validation feedback from the last unlock attempt.
  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrimoireWorkspaceLocked &&
          other.noteCount == noteCount &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode =>
      Object.hash(GrimoireWorkspaceLocked, noteCount, errorMessage);
}

/// Unlocked interactive workspace state holding notes, GraphRAG hits, and
/// script execution outputs.
@immutable
final class GrimoireWorkspaceReady extends GrimoireWorkspaceState {
  /// Creates a [GrimoireWorkspaceReady] state.
  GrimoireWorkspaceReady({
    required List<NoteDocument> notes,
    required this.graph,
    required this.selectedNoteId,
    required this.searchQuery,
    required List<NoteSearchHit> searchHits,
    required this.aiTrustTier,
    Map<String, ScriptExecutionResult> scriptResults = const {},
    this.statusMessage,
  }) : notes = List.unmodifiable(notes),
       searchHits = List.unmodifiable(searchHits),
       scriptResults = Map.unmodifiable(scriptResults);

  /// All notes currently loaded from the vault.
  final List<NoteDocument> notes;

  /// Derived bi-directional note graph.
  final NoteGraph graph;

  /// Identifier of the currently focused note.
  final String selectedNoteId;

  /// Current local search query string.
  final String searchQuery;

  /// Ranked local RAG + GraphRAG search results.
  final List<NoteSearchHit> searchHits;

  /// Active AI privacy tier controlling cloud-exclusion filtering.
  final AiTrustTier aiTrustTier;

  /// Latest execution output keyed by [ScriptBlock.id].
  final Map<String, ScriptExecutionResult> scriptResults;

  /// Optional transient status or conflict feedback message.
  final String? statusMessage;

  /// Currently active [NoteDocument], or `null` when the vault has no notes.
  NoteDocument? get activeNote {
    if (notes.isEmpty) {
      return null;
    }
    for (final note in notes) {
      if (note.id == selectedNoteId) {
        return note;
      }
    }
    return notes.first;
  }

  /// Note IDs containing a link to [activeNote].
  Set<String> get activeBacklinks {
    final current = activeNote;
    return current == null ? const {} : graph.backlinksFor(current.id);
  }

  /// 1-hop neighbor note IDs connected to [activeNote].
  Set<String> get activeNeighbors {
    final current = activeNote;
    return current == null ? const {} : graph.neighbors(current.id);
  }

  /// Returns a copy of this state with updated fields.
  GrimoireWorkspaceReady copyWith({
    List<NoteDocument>? notes,
    NoteGraph? graph,
    String? selectedNoteId,
    String? searchQuery,
    List<NoteSearchHit>? searchHits,
    AiTrustTier? aiTrustTier,
    Map<String, ScriptExecutionResult>? scriptResults,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) => GrimoireWorkspaceReady(
    notes: notes ?? this.notes,
    graph: graph ?? this.graph,
    selectedNoteId: selectedNoteId ?? this.selectedNoteId,
    searchQuery: searchQuery ?? this.searchQuery,
    searchHits: searchHits ?? this.searchHits,
    aiTrustTier: aiTrustTier ?? this.aiTrustTier,
    scriptResults: scriptResults ?? this.scriptResults,
    statusMessage: clearStatusMessage
        ? null
        : (statusMessage ?? this.statusMessage),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! GrimoireWorkspaceReady ||
        other.selectedNoteId != selectedNoteId ||
        other.searchQuery != searchQuery ||
        other.aiTrustTier != aiTrustTier ||
        other.statusMessage != statusMessage ||
        other.notes.length != notes.length ||
        other.searchHits.length != searchHits.length ||
        other.scriptResults.length != scriptResults.length) {
      return false;
    }
    for (var i = 0; i < notes.length; i++) {
      if (notes[i] != other.notes[i]) {
        return false;
      }
    }
    for (var i = 0; i < searchHits.length; i++) {
      if (searchHits[i] != other.searchHits[i]) {
        return false;
      }
    }
    for (final entry in scriptResults.entries) {
      if (other.scriptResults[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    GrimoireWorkspaceReady,
    Object.hashAll(notes),
    selectedNoteId,
    searchQuery,
    Object.hashAll(searchHits),
    aiTrustTier,
    Object.hashAllUnordered([
      for (final e in scriptResults.entries) Object.hash(e.key, e.value),
    ]),
    statusMessage,
  );
}

/// Failure state when loading from [LocalVaultStore] fails unexpectedly.
@immutable
final class GrimoireWorkspaceFailure extends GrimoireWorkspaceState {
  /// Creates a [GrimoireWorkspaceFailure] state.
  const GrimoireWorkspaceFailure({required this.message});

  /// Safe, user-facing failure reason.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrimoireWorkspaceFailure && other.message == message;

  @override
  int get hashCode => Object.hash(GrimoireWorkspaceFailure, message);
}

/// Manages note loading, editing, local GraphRAG search, script execution, and
/// session lock state for Grimoire.
class GrimoireWorkspaceCubit extends Cubit<GrimoireWorkspaceState> {
  /// Creates a [GrimoireWorkspaceCubit].
  GrimoireWorkspaceCubit({
    required this._vaultStore,
    required this._scriptRuntime,
    this._searchIndex = const LocalNoteSearchIndex(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const GrimoireWorkspaceLoading());

  final LocalVaultStore _vaultStore;
  final ScriptRuntime _scriptRuntime;
  final LocalNoteSearchIndex _searchIndex;
  final DateTime Function() _now;

  int _lastKnownNoteCount = 0;

  /// Loads all notes from the vault and emits [GrimoireWorkspaceReady].
  Future<void> load({String? selectNoteId}) async {
    final previous = state;
    final query = previous is GrimoireWorkspaceReady
        ? previous.searchQuery
        : '';
    final trustTier = previous is GrimoireWorkspaceReady
        ? previous.aiTrustTier
        : AiTrustTier.strictLocal;

    emit(const GrimoireWorkspaceLoading());
    try {
      final notes = await _vaultStore.listNotes();
      if (isClosed) {
        return;
      }
      _lastKnownNoteCount = notes.length;
      final selectedId = _resolveSelectedId(notes, selectNoteId);
      final graph = NoteGraph(notes);
      final hits = _searchIndex.search(
        notes: notes,
        query: query,
        trustTier: trustTier,
      );
      emit(
        GrimoireWorkspaceReady(
          notes: notes,
          graph: graph,
          selectedNoteId: selectedId,
          searchQuery: query,
          searchHits: hits,
          aiTrustTier: trustTier,
        ),
      );
    } on Exception catch (error) {
      if (!isClosed) {
        emit(GrimoireWorkspaceFailure(message: error.toString()));
      }
    }
  }

  /// Selects the note identified by [noteId] when it exists in the vault.
  void selectNote(String noteId) {
    final current = state;
    if (current is! GrimoireWorkspaceReady) {
      return;
    }
    final exists = current.notes.any((note) => note.id == noteId);
    if (!exists) {
      emit(current.copyWith(statusMessage: 'Linked note "$noteId" not found.'));
      return;
    }
    emit(current.copyWith(selectedNoteId: noteId, clearStatusMessage: true));
  }

  /// Creates and persists a new [NoteDocument], selecting it upon save.
  Future<void> createNote({
    required String title,
    Set<String> tags = const {},
    bool excludeFromCloudAi = false,
  }) async {
    final current = state;
    if (current is! GrimoireWorkspaceReady) {
      return;
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      emit(current.copyWith(statusMessage: 'Note title must not be empty.'));
      return;
    }

    final nowUtc = _now().toUtc();
    final existingIds = {for (final note in current.notes) note.id};
    final newId = _generateUniqueNoteId(trimmedTitle, existingIds, nowUtc);

    final newNote = NoteDocument(
      id: newId,
      title: trimmedTitle,
      createdAt: nowUtc,
      updatedAt: nowUtc,
      tags: tags,
      excludeFromCloudAi: excludeFromCloudAi,
      blocks: [RichTextBlock(id: 'b1', text: 'New encrypted note.')],
    );

    try {
      final saved = await _vaultStore.saveNote(newNote);
      await _reloadReady(
        selectNoteId: saved.id,
        query: current.searchQuery,
        trustTier: current.aiTrustTier,
        scriptResults: current.scriptResults,
      );
    } on Exception catch (error) {
      if (!isClosed) {
        emit(current.copyWith(statusMessage: error.toString()));
      }
    }
  }

  /// Toggles `excludeFromCloudAi` on the active note and persists it.
  Future<void> toggleExcludeFromCloudAi() async {
    final current = state;
    if (current is! GrimoireWorkspaceReady) {
      return;
    }
    final active = current.activeNote;
    if (active == null) {
      return;
    }
    await _saveUpdatedNote(
      current,
      active.copyWith(excludeFromCloudAi: !active.excludeFromCloudAi),
    );
  }

  /// Appends [block] to the active note and persists it.
  Future<void> addBlock(NoteBlock block) async {
    final current = state;
    if (current is! GrimoireWorkspaceReady) {
      return;
    }
    final active = current.activeNote;
    if (active == null) {
      return;
    }
    await _saveUpdatedNote(
      current,
      active.copyWith(blocks: [...active.blocks, block]),
    );
  }

  /// Replaces the matching block in the active note using [updatedBlock].
  Future<void> updateBlock(NoteBlock updatedBlock) async {
    final current = state;
    if (current is! GrimoireWorkspaceReady) {
      return;
    }
    final active = current.activeNote;
    if (active == null) {
      return;
    }
    final updatedBlocks = [
      for (final block in active.blocks)
        if (block.id == updatedBlock.id) updatedBlock else block,
    ];
    await _saveUpdatedNote(current, active.copyWith(blocks: updatedBlocks));
  }

  /// Removes the block identified by [blockId] from the active note.
  Future<void> deleteBlock(String blockId) async {
    final current = state;
    if (current is! GrimoireWorkspaceReady) {
      return;
    }
    final active = current.activeNote;
    if (active == null) {
      return;
    }
    final remaining = [
      for (final block in active.blocks)
        if (block.id != blockId) block,
    ];
    final nextResults = Map<String, ScriptExecutionResult>.from(
      current.scriptResults,
    )..remove(blockId);
    await _saveUpdatedNote(
      current,
      active.copyWith(blocks: remaining),
      scriptResults: nextResults,
    );
  }

  /// Updates the local search query and refreshes ranked GraphRAG hits.
  void updateSearchQuery(String query) {
    final current = state;
    if (current is! GrimoireWorkspaceReady) {
      return;
    }
    final hits = _searchIndex.search(
      notes: current.notes,
      query: query,
      trustTier: current.aiTrustTier,
    );
    emit(
      current.copyWith(
        searchQuery: query,
        searchHits: hits,
        clearStatusMessage: true,
      ),
    );
  }

  /// Switches the AI trust tier and refreshes filtered search hits.
  void setAiTrustTier(AiTrustTier tier) {
    final current = state;
    if (current is! GrimoireWorkspaceReady) {
      return;
    }
    final hits = _searchIndex.search(
      notes: current.notes,
      query: current.searchQuery,
      trustTier: tier,
    );
    emit(
      current.copyWith(
        aiTrustTier: tier,
        searchHits: hits,
        clearStatusMessage: true,
      ),
    );
  }

  /// Executes the [ScriptBlock] matching [blockId] using [approvedPermissions].
  Future<void> runScriptBlock(
    String blockId, {
    required Set<ScriptPermission> approvedPermissions,
  }) async {
    final current = state;
    if (current is! GrimoireWorkspaceReady) {
      return;
    }
    final active = current.activeNote;
    if (active == null) {
      return;
    }
    ScriptBlock? target;
    for (final block in active.blocks) {
      if (block is ScriptBlock && block.id == blockId) {
        target = block;
        break;
      }
    }
    if (target == null) {
      return;
    }

    final result = await _scriptRuntime.execute(
      target,
      ScriptExecutionContext(
        currentNote: active,
        allNotes: current.notes,
        approvedPermissions: approvedPermissions,
      ),
    );
    if (isClosed) {
      return;
    }
    final latest = state;
    if (latest is! GrimoireWorkspaceReady) {
      return;
    }
    final nextResults = Map<String, ScriptExecutionResult>.from(
      latest.scriptResults,
    )..[blockId] = result;
    emit(latest.copyWith(scriptResults: nextResults, clearStatusMessage: true));
  }

  /// Locks the active workspace session.
  void lockVault() {
    final current = state;
    if (current is GrimoireWorkspaceReady) {
      _lastKnownNoteCount = current.notes.length;
    }
    emit(GrimoireWorkspaceLocked(noteCount: _lastKnownNoteCount));
  }

  /// Unlocks the vault session when a non-empty [passphrase] is supplied.
  Future<void> unlockVault({required String passphrase}) async {
    final current = state;
    final noteCount = current is GrimoireWorkspaceLocked
        ? current.noteCount
        : _lastKnownNoteCount;

    if (passphrase.trim().isEmpty) {
      emit(
        GrimoireWorkspaceLocked(
          noteCount: noteCount,
          errorMessage: 'Passphrase is required to unlock the vault.',
        ),
      );
      return;
    }

    await load();
  }

  Future<void> _saveUpdatedNote(
    GrimoireWorkspaceReady current,
    NoteDocument updated, {
    Map<String, ScriptExecutionResult>? scriptResults,
  }) async {
    try {
      final saved = await _vaultStore.saveNote(
        updated,
        expectedRevision: updated.revision,
      );
      await _reloadReady(
        selectNoteId: saved.id,
        query: current.searchQuery,
        trustTier: current.aiTrustTier,
        scriptResults: scriptResults ?? current.scriptResults,
      );
    } on VaultRevisionConflictException catch (conflict) {
      if (!isClosed) {
        emit(
          current.copyWith(
            statusMessage:
                'Revision conflict on "${conflict.noteId}" '
                '(expected ${conflict.expectedRevision}, '
                'found ${conflict.actualRevision}).',
          ),
        );
      }
    } on Exception catch (error) {
      if (!isClosed) {
        emit(current.copyWith(statusMessage: error.toString()));
      }
    }
  }

  Future<void> _reloadReady({
    required String selectNoteId,
    required String query,
    required AiTrustTier trustTier,
    required Map<String, ScriptExecutionResult> scriptResults,
  }) async {
    final notes = await _vaultStore.listNotes();
    if (isClosed) {
      return;
    }
    _lastKnownNoteCount = notes.length;
    final selectedId = _resolveSelectedId(notes, selectNoteId);
    final graph = NoteGraph(notes);
    final hits = _searchIndex.search(
      notes: notes,
      query: query,
      trustTier: trustTier,
    );
    emit(
      GrimoireWorkspaceReady(
        notes: notes,
        graph: graph,
        selectedNoteId: selectedId,
        searchQuery: query,
        searchHits: hits,
        aiTrustTier: trustTier,
        scriptResults: scriptResults,
      ),
    );
  }

  String _resolveSelectedId(List<NoteDocument> notes, String? preferredId) {
    if (notes.isEmpty) {
      return '';
    }
    if (preferredId != null && notes.any((n) => n.id == preferredId)) {
      return preferredId;
    }
    return notes.first.id;
  }

  String _generateUniqueNoteId(
    String title,
    Set<String> existingIds,
    DateTime timestamp,
  ) {
    final baseSlug = title
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final prefix = baseSlug.isEmpty ? 'note' : baseSlug;
    var candidate = prefix;
    if (!existingIds.contains(candidate)) {
      return candidate;
    }
    candidate = '$prefix-${timestamp.microsecondsSinceEpoch}';
    var counter = 1;
    while (existingIds.contains(candidate)) {
      candidate = '$prefix-${timestamp.microsecondsSinceEpoch}-$counter';
      counter++;
    }
    return candidate;
  }
}
