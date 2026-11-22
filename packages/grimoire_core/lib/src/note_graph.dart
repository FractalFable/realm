import 'dart:collection';

import 'package:meta/meta.dart';

import 'note_document.dart';

/// Pure-Dart directed & backlink graph derived from a collection of
/// [NoteDocument]s for navigation and local GraphRAG retrieval.
@immutable
class NoteGraph._(
  final Map<String, Set<String>> _outgoing,
  final Map<String, Set<String>> _backlinks,
) {
  /// Builds an immutable [NoteGraph] from [documents], rejecting duplicate note
  /// IDs.
  factory NoteGraph(Iterable<NoteDocument> documents) {
    final outgoing = <String, Set<String>>{};
    final backlinks = <String, Set<String>>{};

    for (final doc in documents) {
      if (outgoing.containsKey(doc.id)) {
        throw ArgumentError.value(
          doc.id,
          'documents',
          'Duplicate NoteDocument id "${doc.id}" in NoteGraph.',
        );
      }
      final targets = doc.linkedNoteIds;
      outgoing[doc.id] = targets;
      backlinks.putIfAbsent(doc.id, () => <String>{});
      for (final targetId in targets) {
        backlinks.putIfAbsent(targetId, () => <String>{}).add(doc.id);
      }
    }

    return NoteGraph._(
      Map.unmodifiable({
        for (final MapEntry(:key, :value) in outgoing.entries)
          key: Set<String>.unmodifiable(value),
      }),
      Map.unmodifiable({
        for (final MapEntry(:key, :value) in backlinks.entries)
          key: Set<String>.unmodifiable(value),
      }),
    );
  }

  /// Note IDs directly linked from [noteId].
  Set<String> outgoingLinks(String noteId) => _outgoing[noteId] ?? const {};

  /// Note IDs containing a `NoteLinkBlock` pointing to [noteId].
  Set<String> backlinksFor(String noteId) => _backlinks[noteId] ?? const {};

  /// Returns connected neighbor note IDs within [maxDepth] hops across both
  /// outgoing links and backlinks, excluding [noteId] itself.
  Set<String> neighbors(String noteId, {int maxDepth = 1}) {
    if (maxDepth < 0) {
      throw ArgumentError.value(
        maxDepth,
        'maxDepth',
        'maxDepth must be non-negative.',
      );
    }
    if (maxDepth == 0 ||
        (!_outgoing.containsKey(noteId) && !_backlinks.containsKey(noteId))) {
      return const {};
    }

    final visited = <String>{noteId};
    final result = <String>{};
    final queue = Queue<({String id, int depth})>()
      ..add((id: noteId, depth: 0));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current.depth >= maxDepth) {
        continue;
      }
      final adjacent = <String>{
        ...outgoingLinks(current.id),
        ...backlinksFor(current.id),
      };
      for (final nextId in adjacent) {
        if (visited.add(nextId)) {
          result.add(nextId);
          queue.add((id: nextId, depth: current.depth + 1));
        }
      }
    }

    return Set.unmodifiable(result);
  }
}
