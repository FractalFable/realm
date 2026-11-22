import 'package:meta/meta.dart';

import 'note_block.dart';

DateTime _parseIso8601Utc(Object? raw, String name) {
  if (raw is! String || !_isoTimezonePattern.hasMatch(raw)) {
    throw ArgumentError.value(
      raw,
      name,
      'Expected an ISO-8601 timestamp string with explicit timezone (Z or ±HH:MM).',
    );
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw ArgumentError.value(raw, name, 'Invalid ISO-8601 timestamp.');
  }
  return parsed.toUtc();
}

final RegExp _isoTimezonePattern = RegExp(
  r'(?:Z|[+-]\d{2}:?\d{2})$',
  caseSensitive: false,
);

/// Structured interactive Grimoire note document.
@immutable
class NoteDocument._({
  required final String id,
  required final String title,
  required final List<NoteBlock> blocks,
  required final Set<String> tags,
  required final bool excludeFromCloudAi,
  required final DateTime createdAt,
  required final DateTime updatedAt,
  required final int revision,
}) {
  /// Creates and validates a [NoteDocument], normalizing timestamps to UTC and
  /// enforcing unique block identifiers.
  factory NoteDocument({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    List<NoteBlock> blocks = const [],
    Set<String> tags = const {},
    bool excludeFromCloudAi = false,
    int revision = 0,
  }) {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Note id must not be empty.');
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Note title must not be empty.',
      );
    }
    if (revision < 0) {
      throw ArgumentError.value(
        revision,
        'revision',
        'Revision must be non-negative.',
      );
    }

    final utcCreatedAt = createdAt.toUtc();
    final utcUpdatedAt = updatedAt.toUtc();
    if (utcUpdatedAt.isBefore(utcCreatedAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'updatedAt must not precede createdAt.',
      );
    }

    final seenBlockIds = <String>{};
    for (final block in blocks) {
      if (!seenBlockIds.add(block.id)) {
        throw ArgumentError.value(
          block.id,
          'blocks',
          'Duplicate block id "${block.id}" inside NoteDocument.',
        );
      }
    }

    final normalizedTags = <String>{};
    for (final tag in tags) {
      final trimmedTag = tag.trim();
      if (trimmedTag.isEmpty) {
        throw ArgumentError.value(
          tag,
          'tags',
          'Tags must not be empty or whitespace.',
        );
      }
      normalizedTags.add(trimmedTag);
    }

    return NoteDocument._(
      id: trimmedId,
      title: trimmedTitle,
      blocks: List.unmodifiable(blocks),
      tags: Set.unmodifiable(normalizedTags),
      excludeFromCloudAi: excludeFromCloudAi,
      createdAt: utcCreatedAt,
      updatedAt: utcUpdatedAt,
      revision: revision,
    );
  }

  /// Decodes and validates a [NoteDocument] from JSON.
  factory NoteDocument.fromJson(Map<String, Object?> json) {
    final id = switch (json['id']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'id',
        'Expected a string id.',
      ),
    };
    final title = switch (json['title']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'title',
        'Expected a string title.',
      ),
    };
    final blocks = switch (json['blocks']) {
      null => const <NoteBlock>[],
      final List<Object?> items => [
        for (final item in items)
          switch (item) {
            final Map<String, Object?> map => NoteBlock.fromJson(map),
            final other => throw ArgumentError.value(
              other,
              'blocks',
              'Expected NoteBlock JSON objects.',
            ),
          },
      ],
      final other => throw ArgumentError.value(
        other,
        'blocks',
        'Expected a list of NoteBlock JSON objects.',
      ),
    };
    final tags = switch (json['tags']) {
      null => const <String>{},
      final List<Object?> items => {
        for (final item in items)
          switch (item) {
            final String value => value,
            final other => throw ArgumentError.value(
              other,
              'tags',
              'Expected string tags.',
            ),
          },
      },
      final other => throw ArgumentError.value(
        other,
        'tags',
        'Expected a list of string tags.',
      ),
    };
    final excludeFromCloudAi = switch (json['excludeFromCloudAi']) {
      null => false,
      final bool value => value,
      final other => throw ArgumentError.value(
        other,
        'excludeFromCloudAi',
        'Expected a bool for excludeFromCloudAi.',
      ),
    };
    final createdAt = _parseIso8601Utc(json['createdAt'], 'createdAt');
    final updatedAt = _parseIso8601Utc(json['updatedAt'], 'updatedAt');
    final revision = switch (json['revision']) {
      null => 0,
      final int value => value,
      final other => throw ArgumentError.value(
        other,
        'revision',
        'Expected an integer revision.',
      ),
    };

    return NoteDocument(
      id: id,
      title: title,
      blocks: blocks,
      tags: tags,
      excludeFromCloudAi: excludeFromCloudAi,
      createdAt: createdAt,
      updatedAt: updatedAt,
      revision: revision,
    );
  }

  /// IDs of notes referenced directly by [NoteLinkBlock]s inside this note.
  Set<String> get linkedNoteIds => Set.unmodifiable({
    for (final block in blocks)
      if (block case NoteLinkBlock(:final targetNoteId)) targetNoteId,
  });

  /// Serializes this document to JSON.
  Map<String, Object?> toJson() {
    final sortedTags = tags.toList()..sort();
    return {
      'id': id,
      'title': title,
      'blocks': [for (final block in blocks) block.toJson()],
      if (sortedTags.isNotEmpty) 'tags': sortedTags,
      'excludeFromCloudAi': excludeFromCloudAi,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'revision': revision,
    };
  }

  /// Returns a copy of this note with updated fields.
  NoteDocument copyWith({
    String? id,
    String? title,
    List<NoteBlock>? blocks,
    Set<String>? tags,
    bool? excludeFromCloudAi,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? revision,
  }) => NoteDocument(
    id: id ?? this.id,
    title: title ?? this.title,
    blocks: blocks ?? this.blocks,
    tags: tags ?? this.tags,
    excludeFromCloudAi: excludeFromCloudAi ?? this.excludeFromCloudAi,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! NoteDocument ||
        other.id != id ||
        other.title != title ||
        other.excludeFromCloudAi != excludeFromCloudAi ||
        other.createdAt != createdAt ||
        other.updatedAt != updatedAt ||
        other.revision != revision ||
        other.blocks.length != blocks.length ||
        other.tags.length != tags.length ||
        !tags.containsAll(other.tags)) {
      return false;
    }
    for (var i = 0; i < blocks.length; i++) {
      if (blocks[i] != other.blocks[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    Object.hashAll(blocks),
    Object.hashAllUnordered(tags),
    excludeFromCloudAi,
    createdAt,
    updatedAt,
    revision,
  );
}
