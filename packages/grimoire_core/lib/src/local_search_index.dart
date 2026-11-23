import 'package:meta/meta.dart';

import 'note_block.dart';
import 'note_document.dart';
import 'note_graph.dart';

/// User-configured AI privacy tier controlling what client-side RAG may expose.
enum AiTrustTier {
  strictLocal,
  optInByokCloud;

  /// Parses an [AiTrustTier] from its enum [name].
  static AiTrustTier fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError.value(name, 'trustTier', 'Unknown AiTrustTier.');
  }
}

/// Ranked search result from [LocalNoteSearchIndex] with GraphRAG neighbors.
@immutable
final class NoteSearchHit {
  /// Creates a [NoteSearchHit].
  NoteSearchHit({
    required this.note,
    required this.score,
    Set<String> matchedTerms = const {},
    Set<String> graphNeighborIds = const {},
  }) : matchedTerms = Set.unmodifiable(matchedTerms),
       graphNeighborIds = Set.unmodifiable(graphNeighborIds);

  /// Matched or graph-linked note document.
  final NoteDocument note;

  /// Deterministic relevance score (higher is more relevant).
  final int score;

  /// Normalized query terms matched directly in this note.
  final Set<String> matchedTerms;

  /// Neighbor note IDs within the configured graph depth allowed by trust tier.
  final Set<String> graphNeighborIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteSearchHit &&
          other.note == note &&
          other.score == score &&
          other.matchedTerms.length == matchedTerms.length &&
          matchedTerms.containsAll(other.matchedTerms) &&
          other.graphNeighborIds.length == graphNeighborIds.length &&
          graphNeighborIds.containsAll(other.graphNeighborIds);

  @override
  int get hashCode => Object.hash(
    note,
    score,
    Object.hashAllUnordered(matchedTerms),
    Object.hashAllUnordered(graphNeighborIds),
  );
}

/// Pure-Dart client-side keyword + GraphRAG index respecting [AiTrustTier].
final class LocalNoteSearchIndex {
  /// Creates a [LocalNoteSearchIndex].
  const LocalNoteSearchIndex();

  static final RegExp _tokenPattern = RegExp('[a-z0-9]+');

  /// Searches [notes] using keyword scoring and [NoteGraph] expansion while
  /// excluding `excludeFromCloudAi` notes whenever [trustTier] is
  /// [AiTrustTier.optInByokCloud].
  List<NoteSearchHit> search({
    required Iterable<NoteDocument> notes,
    required String query,
    AiTrustTier trustTier = AiTrustTier.strictLocal,
    Set<String> requiredTags = const {},
    int graphDepth = 1,
  }) {
    if (graphDepth < 0) {
      throw ArgumentError.value(
        graphDepth,
        'graphDepth',
        'graphDepth must be non-negative.',
      );
    }

    final allowedNotes = <NoteDocument>[
      for (final note in notes)
        if (trustTier == AiTrustTier.strictLocal || !note.excludeFromCloudAi)
          note,
    ];
    final allowedIds = {for (final note in allowedNotes) note.id};
    final graph = NoteGraph(allowedNotes);

    final normalizedRequiredTags = {
      for (final tag in requiredTags) tag.trim().toLowerCase(),
    }..removeWhere((tag) => tag.isEmpty);

    final candidates = <NoteDocument>[
      for (final note in allowedNotes)
        if (normalizedRequiredTags.isEmpty ||
            normalizedRequiredTags.every(
              (requiredTag) =>
                  note.tags.any((t) => t.toLowerCase() == requiredTag),
            ))
          note,
    ];

    Set<String> allowedNeighborsFor(String noteId) => Set.unmodifiable({
      for (final neighborId in graph.neighbors(noteId, maxDepth: graphDepth))
        if (allowedIds.contains(neighborId)) neighborId,
    });

    final terms = {
      for (final match in _tokenPattern.allMatches(query.toLowerCase()))
        match.group(0)!,
    };

    if (terms.isEmpty) {
      final hits = [
        for (final note in candidates)
          NoteSearchHit(
            note: note,
            score: 1,
            graphNeighborIds: allowedNeighborsFor(note.id),
          ),
      ];
      return _sortAndFreeze(hits);
    }

    final scored = <String, _ScoredCandidate>{};
    final directMatchedIds = <String>{};

    for (final note in candidates) {
      final titleLower = note.title.toLowerCase();
      final lowerTags = {for (final tag in note.tags) tag.toLowerCase()};
      final bodyLower = _extractBlockText(note).toLowerCase();

      var score = 0;
      final matched = <String>{};
      for (final term in terms) {
        var termMatched = false;
        if (titleLower.contains(term)) {
          score += 10;
          termMatched = true;
        }
        if (lowerTags.contains(term)) {
          score += 8;
          termMatched = true;
        }
        if (bodyLower.contains(term)) {
          score += 4;
          termMatched = true;
        }
        if (termMatched) {
          matched.add(term);
        }
      }

      if (score > 0) {
        directMatchedIds.add(note.id);
      }
      scored[note.id] = _ScoredCandidate(
        note: note,
        score: score,
        matchedTerms: matched,
      );
    }

    if (graphDepth > 0 && directMatchedIds.isNotEmpty) {
      final neighborBoostIds = <String>{};
      for (final directId in directMatchedIds) {
        neighborBoostIds.addAll(allowedNeighborsFor(directId));
      }
      for (final neighborId in neighborBoostIds) {
        final candidate = scored[neighborId];
        if (candidate != null && candidate.score == 0) {
          scored[neighborId] = _ScoredCandidate(
            note: candidate.note,
            score: 2,
            matchedTerms: const {},
          );
        }
      }
    }

    final hits = [
      for (final entry in scored.values)
        if (entry.score > 0)
          NoteSearchHit(
            note: entry.note,
            score: entry.score,
            matchedTerms: entry.matchedTerms,
            graphNeighborIds: allowedNeighborsFor(entry.note.id),
          ),
    ];

    return _sortAndFreeze(hits);
  }

  List<NoteSearchHit> _sortAndFreeze(List<NoteSearchHit> hits) {
    hits.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) {
        return scoreCmp;
      }
      final timeCmp = b.note.updatedAt.compareTo(a.note.updatedAt);
      if (timeCmp != 0) {
        return timeCmp;
      }
      return a.note.id.compareTo(b.note.id);
    });
    return List.unmodifiable(hits);
  }

  String _extractBlockText(NoteDocument note) {
    final buffer = StringBuffer();
    for (final block in note.blocks) {
      switch (block) {
        case RichTextBlock(:final text):
          buffer.writeln(text);
        case NoteLinkBlock(:final alias, :final targetNoteId):
          if (alias != null) {
            buffer.writeln(alias);
          }
          buffer.writeln(targetNoteId);
        case WebEmbedBlock(:final title, :final url):
          if (title != null) {
            buffer.writeln(title);
          }
          buffer.writeln(url.host);
        case ScriptBlock(:final title, :final source):
          if (title != null) {
            buffer.writeln(title);
          }
          buffer.writeln(source);
        case A2uiBlock(:final surfaceId, :final prompt):
          if (prompt != null) {
            buffer.writeln(prompt);
          }
          buffer.writeln(surfaceId);
      }
    }
    return buffer.toString();
  }
}

final class _ScoredCandidate {
  const _ScoredCandidate({
    required this.note,
    required this.score,
    required this.matchedTerms,
  });

  final NoteDocument note;
  final int score;
  final Set<String> matchedTerms;
}
