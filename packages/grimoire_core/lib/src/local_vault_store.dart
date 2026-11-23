import 'package:meta/meta.dart';

import 'note_document.dart';

/// Thrown when saving a note with an [expectedRevision] that does not match the
/// currently persisted revision in a [LocalVaultStore].
@immutable
final class VaultRevisionConflictException implements Exception {
  /// Creates a [VaultRevisionConflictException].
  const VaultRevisionConflictException({
    required this.noteId,
    required this.expectedRevision,
    required this.actualRevision,
  });

  /// Identifier of the note that experienced the conflict.
  final String noteId;

  /// Revision expected by the caller.
  final int expectedRevision;

  /// Revision currently stored (`-1` when the note does not exist).
  final int actualRevision;

  @override
  String toString() =>
      'VaultRevisionConflictException(noteId: $noteId, '
      'expectedRevision: $expectedRevision, actualRevision: $actualRevision)';
}

/// Platform-neutral persistence contract for Grimoire note vaults.
abstract interface class LocalVaultStore {
  /// Lists all notes in the vault ordered deterministically.
  Future<List<NoteDocument>> listNotes();

  /// Loads a single note by [noteId], or `null` if absent.
  Future<NoteDocument?> getNote(String noteId);

  /// Saves [note], enforcing optimistic concurrency when [expectedRevision] is
  /// provided.
  Future<NoteDocument> saveNote(NoteDocument note, {int? expectedRevision});

  /// Deletes the note identified by [noteId], returning `true` if removed.
  Future<bool> deleteNote(String noteId);
}

/// Pure-Dart in-memory [LocalVaultStore] with optimistic revision checks and
/// deterministic ordering.
final class InMemoryVaultStore implements LocalVaultStore {
  /// Creates an [InMemoryVaultStore] seeded with [initialNotes].
  InMemoryVaultStore({
    Iterable<NoteDocument> initialNotes = const [],
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    for (final note in initialNotes) {
      if (_notes.containsKey(note.id)) {
        throw ArgumentError.value(
          note.id,
          'initialNotes',
          'Duplicate NoteDocument id "${note.id}" in InMemoryVaultStore.',
        );
      }
      _notes[note.id] = note;
    }
  }

  final Map<String, NoteDocument> _notes = {};
  final DateTime Function() _now;

  @override
  Future<List<NoteDocument>> listNotes() async {
    final sorted = _notes.values.toList()
      ..sort((a, b) {
        final timeCmp = b.updatedAt.compareTo(a.updatedAt);
        if (timeCmp != 0) {
          return timeCmp;
        }
        return a.id.compareTo(b.id);
      });
    return List.unmodifiable(sorted);
  }

  @override
  Future<NoteDocument?> getNote(String noteId) async => _notes[noteId];

  @override
  Future<NoteDocument> saveNote(
    NoteDocument note, {
    int? expectedRevision,
  }) async {
    final existing = _notes[note.id];
    if (expectedRevision != null) {
      if (existing == null) {
        throw VaultRevisionConflictException(
          noteId: note.id,
          expectedRevision: expectedRevision,
          actualRevision: -1,
        );
      }
      if (existing.revision != expectedRevision) {
        throw VaultRevisionConflictException(
          noteId: note.id,
          expectedRevision: expectedRevision,
          actualRevision: existing.revision,
        );
      }
    }

    final nowUtc = _now().toUtc();
    final effectiveUpdatedAt = nowUtc.isBefore(note.createdAt)
        ? note.createdAt
        : nowUtc;
    final nextRevision = existing == null
        ? note.revision
        : existing.revision + 1;
    final saved = note.copyWith(
      updatedAt: effectiveUpdatedAt,
      revision: nextRevision,
    );
    _notes[saved.id] = saved;
    return saved;
  }

  @override
  Future<bool> deleteNote(String noteId) async => _notes.remove(noteId) != null;
}
