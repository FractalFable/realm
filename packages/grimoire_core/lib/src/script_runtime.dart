import 'package:meta/meta.dart';

import 'note_block.dart';
import 'note_document.dart';
import 'note_graph.dart';

bool _deepMapEquals(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final MapEntry(:key, :value) in a.entries) {
    if (!b.containsKey(key) || !_deepValueEquals(value, b[key])) {
      return false;
    }
  }
  return true;
}

bool _deepValueEquals(Object? a, Object? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a is Map<String, Object?> && b is Map<String, Object?>) {
    return _deepMapEquals(a, b);
  }
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!_deepValueEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

int _deepValueHash(Object? value) => switch (value) {
  final Map<String, Object?> map => Object.hashAllUnordered(
    map.entries.map((e) => Object.hash(e.key, _deepValueHash(e.value))),
  ),
  final List<Object?> list => Object.hashAll(list.map(_deepValueHash)),
  _ => value.hashCode,
};

Map<String, Object?> _freezeJsonMap(Map<String, Object?> input) {
  final copy = <String, Object?>{};
  for (final MapEntry(:key, :value) in input.entries) {
    copy[key] = switch (value) {
      final Map<String, Object?> nested => _freezeJsonMap(nested),
      final List<Object?> list => _freezeJsonList(list),
      _ => value,
    };
  }
  return Map.unmodifiable(copy);
}

List<Object?> _freezeJsonList(List<Object?> input) => List.unmodifiable([
  for (final item in input)
    switch (item) {
      final Map<String, Object?> nested => _freezeJsonMap(nested),
      final List<Object?> nestedList => _freezeJsonList(nestedList),
      _ => item,
    },
]);

/// Execution inputs supplied to a [ScriptRuntime] for a single [ScriptBlock].
@immutable
final class ScriptExecutionContext {
  /// Creates a [ScriptExecutionContext].
  ScriptExecutionContext({
    required this.currentNote,
    required List<NoteDocument> allNotes,
    Set<ScriptPermission> approvedPermissions = const {},
  }) : allNotes = List.unmodifiable(allNotes),
       approvedPermissions = Set.unmodifiable(approvedPermissions);

  /// Active note containing the script block.
  final NoteDocument currentNote;

  /// All notes visible in the unlocked vault.
  final List<NoteDocument> allNotes;

  /// Permissions explicitly approved by the user for this execution.
  final Set<ScriptPermission> approvedPermissions;
}

/// Sealed outcome produced by executing a [ScriptBlock].
@immutable
sealed class ScriptExecutionResult {
  const ScriptExecutionResult();
}

/// Structured non-UI script output.
@immutable
final class ScriptValueResult extends ScriptExecutionResult {
  /// Creates a [ScriptValueResult].
  ScriptValueResult({
    required this.summary,
    Map<String, Object?> data = const {},
  }) : data = _freezeJsonMap(data);

  /// Human-readable summary of the script result.
  final String summary;

  /// Structured JSON-safe output map.
  final Map<String, Object?> data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScriptValueResult &&
          other.summary == summary &&
          _deepMapEquals(data, other.data);

  @override
  int get hashCode =>
      Object.hash(ScriptValueResult, summary, _deepValueHash(data));
}

/// Declarative A2UI surface messages emitted by a script with `emitA2ui`.
@immutable
final class ScriptA2uiResult extends ScriptExecutionResult {
  /// Creates a [ScriptA2uiResult].
  ScriptA2uiResult({
    required this.surfaceId,
    required this.summary,
    required List<Map<String, Object?>> messages,
  }) : messages = List.unmodifiable([
         for (final message in messages) _freezeJsonMap(message),
       ]);

  /// Target A2UI surface identifier.
  final String surfaceId;

  /// Human-readable summary of the generated surface.
  final String summary;

  /// Ordered A2UI v1.0 JSON envelope messages.
  final List<Map<String, Object?>> messages;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ScriptA2uiResult ||
        other.surfaceId != surfaceId ||
        other.summary != summary ||
        other.messages.length != messages.length) {
      return false;
    }
    for (var i = 0; i < messages.length; i++) {
      if (!_deepMapEquals(messages[i], other.messages[i])) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    ScriptA2uiResult,
    surfaceId,
    summary,
    Object.hashAll(messages.map(_deepValueHash)),
  );
}

/// Failure or permission denial returned by [ScriptRuntime.execute].
@immutable
final class ScriptErrorResult extends ScriptExecutionResult {
  /// Creates a [ScriptErrorResult].
  ScriptErrorResult({
    required this.message,
    Set<ScriptPermission> missingPermissions = const {},
  }) : missingPermissions = Set.unmodifiable(missingPermissions);

  /// Safe, user-facing failure reason.
  final String message;

  /// Permissions required by the script that were not granted/approved.
  final Set<ScriptPermission> missingPermissions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScriptErrorResult &&
          other.message == message &&
          other.missingPermissions.length == missingPermissions.length &&
          missingPermissions.containsAll(other.missingPermissions);

  @override
  int get hashCode => Object.hash(
    ScriptErrorResult,
    message,
    Object.hashAllUnordered(missingPermissions),
  );
}

/// Platform-neutral sandboxed script execution interface.
abstract interface class ScriptRuntime {
  /// Executes [block] under [context], enforcing capability permissions.
  Future<ScriptExecutionResult> execute(
    ScriptBlock block,
    ScriptExecutionContext context,
  );
}

/// Pure-Dart capability-gated script evaluator for offline and test contexts.
///
/// Inspects required capabilities from [ScriptBlock.source], enforces both
/// block-level `grantedPermissions` and runtime `approvedPermissions`, blocks
/// network calls in the offline sandbox, and computes live note/graph metrics.
final class SandboxedScriptRuntime implements ScriptRuntime {
  /// Creates a [SandboxedScriptRuntime] emitting A2UI surfaces for
  /// [a2uiCatalogId].
  const SandboxedScriptRuntime({this.a2uiCatalogId = 'basic_catalog'});

  /// Catalog identifier placed on emitted A2UI `createSurface` messages.
  final String a2uiCatalogId;

  @override
  Future<ScriptExecutionResult> execute(
    ScriptBlock block,
    ScriptExecutionContext context,
  ) async {
    final requiredPermissions = _inferRequiredPermissions(block.source);
    final effectivePermissions = block.grantedPermissions.intersection(
      context.approvedPermissions,
    );
    final missingPermissions = requiredPermissions.difference(
      effectivePermissions,
    );

    if (missingPermissions.isNotEmpty) {
      final names = missingPermissions.map((p) => p.name).toList()..sort();
      return ScriptErrorResult(
        message: 'Missing required permission(s): ${names.join(', ')}.',
        missingPermissions: missingPermissions,
      );
    }

    if (requiredPermissions.contains(ScriptPermission.network)) {
      return ScriptErrorResult(
        message: 'Network access is blocked in the offline sandbox.',
      );
    }

    final graph = NoteGraph(context.allNotes);
    final note = context.currentNote;
    final checklistBlocks = [
      for (final b in note.blocks)
        if (b is RichTextBlock && b.style == RichTextStyle.checklist) b,
    ];
    final checklistDone = checklistBlocks
        .where((b) => b.checked ?? false)
        .length;
    final outgoingCount = graph.outgoingLinks(note.id).length;
    final backlinkCount = graph.backlinksFor(note.id).length;
    final linkedCount = outgoingCount + backlinkCount;

    final metrics = <String, Object?>{
      'noteId': note.id,
      'blockCount': note.blocks.length,
      'checklistTotal': checklistBlocks.length,
      'checklistDone': checklistDone,
      'outgoingLinks': outgoingCount,
      'backlinks': backlinkCount,
      'linkedCount': linkedCount,
      if (effectivePermissions.contains(ScriptPermission.queryNotes))
        'totalNotes': context.allNotes.length,
    };

    final summary =
        '${note.title}: ${note.blocks.length} blocks, '
        '$outgoingCount outgoing, $backlinkCount backlinks'
        '${checklistBlocks.isEmpty ? '' : ', $checklistDone/${checklistBlocks.length} tasks done'}';

    if (requiredPermissions.contains(ScriptPermission.emitA2ui) &&
        effectivePermissions.contains(ScriptPermission.emitA2ui)) {
      final surfaceId = 'script_${block.id}';
      return ScriptA2uiResult(
        surfaceId: surfaceId,
        summary: summary,
        messages: [
          {
            'version': '1.0',
            'createSurface': {
              'surfaceId': surfaceId,
              'catalogId': a2uiCatalogId,
              'components': [
                {'id': 'root', 'component': 'Card', 'child': 'summary_text'},
                {'id': 'summary_text', 'component': 'Text', 'text': summary},
              ],
            },
          },
        ],
      );
    }

    return ScriptValueResult(summary: summary, data: metrics);
  }

  Set<ScriptPermission> _inferRequiredPermissions(String source) {
    final lower = source.toLowerCase();
    final required = <ScriptPermission>{ScriptPermission.readCurrentNote};
    if (lower.contains('fetch(') || lower.contains('http')) {
      required.add(ScriptPermission.network);
    }
    if (lower.contains('querynotes') || lower.contains('allnotes')) {
      required.add(ScriptPermission.queryNotes);
    }
    if (lower.contains('a2ui') ||
        lower.contains('createsurface') ||
        lower.contains('emit') ||
        lower.contains('linkedcount')) {
      required.add(ScriptPermission.emitA2ui);
    }
    return required;
  }
}
