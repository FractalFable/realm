import 'package:meta/meta.dart';

String _requireNonEmpty(String value, String name) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, name, '$name must not be empty.');
  }
  return trimmed;
}

String _readRequiredString(Map<String, Object?> json, String key) =>
    switch (json[key]) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        key,
        'Expected a string for $key.',
      ),
    };

String? _readOptionalString(Map<String, Object?> json, String key) =>
    switch (json[key]) {
      null => null,
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        key,
        'Expected a string or null for $key.',
      ),
    };

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

/// Text presentation styles for [RichTextBlock].
enum RichTextStyle {
  paragraph,
  heading1,
  heading2,
  heading3,
  quote,
  checklist,
  code;

  /// Parses a [RichTextStyle] from its JSON [name].
  static RichTextStyle fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError.value(name, 'style', 'Unknown RichTextStyle.');
  }
}

/// Supported scripting languages for [ScriptBlock].
enum ScriptLanguage {
  javascript;

  /// Parses a [ScriptLanguage] from its JSON [name].
  static ScriptLanguage fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError.value(name, 'language', 'Unknown ScriptLanguage.');
  }
}

/// Capability permissions that a [ScriptBlock] may request with user consent.
enum ScriptPermission {
  readCurrentNote,
  queryNotes,
  network,
  emitA2ui;

  /// Parses a [ScriptPermission] from its JSON [name].
  static ScriptPermission fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError.value(name, 'permission', 'Unknown ScriptPermission.');
  }
}

/// Base type for structured interactive blocks inside a Grimoire note.
@immutable
sealed class NoteBlock {
  const NoteBlock({required this.id});

  /// Decodes a [NoteBlock] variant from JSON using its `type` discriminator.
  factory NoteBlock.fromJson(Map<String, Object?> json) {
    final type = _readRequiredString(json, 'type');
    return switch (type) {
      'richText' => RichTextBlock.fromJson(json),
      'noteLink' => NoteLinkBlock.fromJson(json),
      'webEmbed' => WebEmbedBlock.fromJson(json),
      'script' => ScriptBlock.fromJson(json),
      'a2ui' => A2uiBlock.fromJson(json),
      _ => throw ArgumentError.value(type, 'type', 'Unknown NoteBlock type.'),
    };
  }

  /// Stable block identifier unique within a note document.
  final String id;

  /// Wire discriminator string for this block variant.
  String get type;

  /// Serializes this block to JSON.
  Map<String, Object?> toJson();
}

/// Structured rich text, heading, quote, checklist, or code block.
@immutable
final class RichTextBlock extends NoteBlock {
  /// Creates and validates a [RichTextBlock].
  RichTextBlock({
    required String id,
    required this.text,
    this.style = .paragraph,
    this.checked,
  }) : super(id: _requireNonEmpty(id, 'id')) {
    if (checked != null && style != .checklist) {
      throw ArgumentError.value(
        checked,
        'checked',
        'Only checklist blocks may define checked state.',
      );
    }
  }

  /// Decodes a [RichTextBlock] from JSON.
  factory RichTextBlock.fromJson(Map<String, Object?> json) {
    final id = _readRequiredString(json, 'id');
    final text = _readRequiredString(json, 'text');
    final style = switch (json['style']) {
      null => RichTextStyle.paragraph,
      final String value => RichTextStyle.fromName(value),
      final other => throw ArgumentError.value(
        other,
        'style',
        'Expected a RichTextStyle string.',
      ),
    };
    final checked = switch (json['checked']) {
      null => null,
      final bool value => value,
      final other => throw ArgumentError.value(
        other,
        'checked',
        'Expected a bool or null for checked.',
      ),
    };

    return RichTextBlock(id: id, text: text, style: style, checked: checked);
  }

  final String text;
  final RichTextStyle style;
  final bool? checked;

  @override
  String get type => 'richText';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'text': text,
    'style': style.name,
    'checked': ?checked,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RichTextBlock &&
          other.id == id &&
          other.text == text &&
          other.style == style &&
          other.checked == checked;

  @override
  int get hashCode => Object.hash(type, id, text, style, checked);
}

/// Bi-directional link to another Grimoire note (and optional target block).
@immutable
final class NoteLinkBlock extends NoteBlock {
  /// Creates and validates a [NoteLinkBlock].
  NoteLinkBlock({
    required String id,
    required String targetNoteId,
    String? alias,
    String? targetBlockId,
  }) : targetNoteId = _requireNonEmpty(targetNoteId, 'targetNoteId'),
       alias = alias == null ? null : _requireNonEmpty(alias, 'alias'),
       targetBlockId = targetBlockId == null
           ? null
           : _requireNonEmpty(targetBlockId, 'targetBlockId'),
       super(id: _requireNonEmpty(id, 'id'));

  /// Decodes a [NoteLinkBlock] from JSON.
  factory NoteLinkBlock.fromJson(Map<String, Object?> json) => NoteLinkBlock(
    id: _readRequiredString(json, 'id'),
    targetNoteId: _readRequiredString(json, 'targetNoteId'),
    alias: _readOptionalString(json, 'alias'),
    targetBlockId: _readOptionalString(json, 'targetBlockId'),
  );

  final String targetNoteId;
  final String? alias;
  final String? targetBlockId;

  @override
  String get type => 'noteLink';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'targetNoteId': targetNoteId,
    'alias': ?alias,
    'targetBlockId': ?targetBlockId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteLinkBlock &&
          other.id == id &&
          other.targetNoteId == targetNoteId &&
          other.alias == alias &&
          other.targetBlockId == targetBlockId;

  @override
  int get hashCode => Object.hash(type, id, targetNoteId, alias, targetBlockId);
}

/// Sandboxed HTTPS website embed inside a Grimoire note.
@immutable
final class WebEmbedBlock extends NoteBlock {
  /// Creates and validates a [WebEmbedBlock], enforcing HTTPS-only URIs with
  /// a non-empty host and no embedded userinfo.
  WebEmbedBlock({
    required String id,
    required this.url,
    String? title,
    this.allowInteractive = false,
  }) : title = title == null ? null : _requireNonEmpty(title, 'title'),
       super(id: _requireNonEmpty(id, 'id')) {
    if (url.scheme != 'https' || !url.hasAuthority || url.host.isEmpty) {
      throw ArgumentError.value(
        url,
        'url',
        'WebEmbedBlock requires an absolute https URI with a non-empty host.',
      );
    }
    if (url.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        url,
        'url',
        'WebEmbedBlock URI must not contain userinfo.',
      );
    }
  }

  /// Decodes a [WebEmbedBlock] from JSON.
  factory WebEmbedBlock.fromJson(Map<String, Object?> json) {
    final id = _readRequiredString(json, 'id');
    final rawUrl = _readRequiredString(json, 'url');
    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null) {
      throw ArgumentError.value(rawUrl, 'url', 'Invalid WebEmbedBlock URI.');
    }
    final title = _readOptionalString(json, 'title');
    final allowInteractive = switch (json['allowInteractive']) {
      null => false,
      final bool value => value,
      final other => throw ArgumentError.value(
        other,
        'allowInteractive',
        'Expected a bool for allowInteractive.',
      ),
    };

    return WebEmbedBlock(
      id: id,
      url: parsed,
      title: title,
      allowInteractive: allowInteractive,
    );
  }

  final Uri url;
  final String? title;
  final bool allowInteractive;

  @override
  String get type => 'webEmbed';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'url': url.toString(),
    'title': ?title,
    'allowInteractive': allowInteractive,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebEmbedBlock &&
          other.id == id &&
          other.url == url &&
          other.title == title &&
          other.allowInteractive == allowInteractive;

  @override
  int get hashCode => Object.hash(type, id, url, title, allowInteractive);
}

/// Sandboxed inline script block with explicit user-granted permissions.
@immutable
final class ScriptBlock extends NoteBlock {
  /// Creates and validates a [ScriptBlock].
  ScriptBlock({
    required String id,
    required this.source,
    this.language = .javascript,
    Set<ScriptPermission> grantedPermissions = const {},
    String? title,
  }) : grantedPermissions = Set.unmodifiable(grantedPermissions),
       title = title == null ? null : _requireNonEmpty(title, 'title'),
       super(id: _requireNonEmpty(id, 'id')) {
    if (source.trim().isEmpty) {
      throw ArgumentError.value(
        source,
        'source',
        'Script source must not be empty.',
      );
    }
  }

  /// Decodes a [ScriptBlock] from JSON.
  factory ScriptBlock.fromJson(Map<String, Object?> json) {
    final id = _readRequiredString(json, 'id');
    final source = _readRequiredString(json, 'source');
    final language = switch (json['language']) {
      null => ScriptLanguage.javascript,
      final String value => ScriptLanguage.fromName(value),
      final other => throw ArgumentError.value(
        other,
        'language',
        'Expected a ScriptLanguage string.',
      ),
    };
    final permissions = switch (json['grantedPermissions']) {
      null => <ScriptPermission>{},
      final List<Object?> items => {
        for (final item in items)
          switch (item) {
            final String value => ScriptPermission.fromName(value),
            final other => throw ArgumentError.value(
              other,
              'grantedPermissions',
              'Expected ScriptPermission strings.',
            ),
          },
      },
      final other => throw ArgumentError.value(
        other,
        'grantedPermissions',
        'Expected a list of ScriptPermission strings.',
      ),
    };
    final title = _readOptionalString(json, 'title');

    return ScriptBlock(
      id: id,
      source: source,
      language: language,
      grantedPermissions: permissions,
      title: title,
    );
  }

  final String source;
  final ScriptLanguage language;
  final Set<ScriptPermission> grantedPermissions;
  final String? title;

  @override
  String get type => 'script';

  @override
  Map<String, Object?> toJson() {
    final sortedPermissions = grantedPermissions.map((p) => p.name).toList()
      ..sort();
    return {
      'type': type,
      'id': id,
      'source': source,
      'language': language.name,
      if (sortedPermissions.isNotEmpty) 'grantedPermissions': sortedPermissions,
      'title': ?title,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ScriptBlock &&
        other.id == id &&
        other.source == source &&
        other.language == language &&
        other.title == title &&
        other.grantedPermissions.length == grantedPermissions.length &&
        grantedPermissions.containsAll(other.grantedPermissions);
  }

  @override
  int get hashCode => Object.hash(
    type,
    id,
    source,
    language,
    title,
    Object.hashAllUnordered(grantedPermissions),
  );
}

/// Declarative Agent-to-UI surface embedded in a Grimoire note.
@immutable
final class A2uiBlock extends NoteBlock {
  /// Creates and validates an [A2uiBlock].
  A2uiBlock({
    required String id,
    required String surfaceId,
    String? prompt,
    Map<String, Object?>? cachedSurfaceJson,
  }) : surfaceId = _requireNonEmpty(surfaceId, 'surfaceId'),
       prompt = prompt == null ? null : _requireNonEmpty(prompt, 'prompt'),
       cachedSurfaceJson = cachedSurfaceJson == null
           ? null
           : _freezeJsonMap(cachedSurfaceJson),
       super(id: _requireNonEmpty(id, 'id'));

  /// Decodes an [A2uiBlock] from JSON.
  factory A2uiBlock.fromJson(Map<String, Object?> json) {
    final id = _readRequiredString(json, 'id');
    final surfaceId = _readRequiredString(json, 'surfaceId');
    final prompt = _readOptionalString(json, 'prompt');
    final cachedSurfaceJson = switch (json['cachedSurfaceJson']) {
      null => null,
      final Map<String, Object?> map => map,
      final other => throw ArgumentError.value(
        other,
        'cachedSurfaceJson',
        'Expected a JSON object or null for cachedSurfaceJson.',
      ),
    };

    return A2uiBlock(
      id: id,
      surfaceId: surfaceId,
      prompt: prompt,
      cachedSurfaceJson: cachedSurfaceJson,
    );
  }

  final String surfaceId;
  final String? prompt;
  final Map<String, Object?>? cachedSurfaceJson;

  @override
  String get type => 'a2ui';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'surfaceId': surfaceId,
    'prompt': ?prompt,
    'cachedSurfaceJson': ?cachedSurfaceJson,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! A2uiBlock ||
        other.id != id ||
        other.surfaceId != surfaceId ||
        other.prompt != prompt) {
      return false;
    }
    final a = cachedSurfaceJson;
    final b = other.cachedSurfaceJson;
    if (a == null || b == null) {
      return a == b;
    }
    return _deepMapEquals(a, b);
  }

  @override
  int get hashCode => Object.hash(
    type,
    id,
    surfaceId,
    prompt,
    cachedSurfaceJson == null ? null : _deepValueHash(cachedSurfaceJson),
  );
}
