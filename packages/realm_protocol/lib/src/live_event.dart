import 'package:meta/meta.dart';

final RegExp _isoTimezonePattern = RegExp(
  r'(?:Z|[+-]\d{2}:?\d{2})$',
  caseSensitive: false,
);

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

/// App-neutral WebSocket live-update envelope carrying an app-defined [type]
/// and immutable JSON [payload].
@immutable
class const LiveEvent._({
  required final String type,
  required final String eventId,
  required final DateTime occurredAt,
  required final Map<String, Object?> payload,
}) {
  /// Creates and validates a [LiveEvent], freezing [payload] and normalizing
  /// [occurredAt] to UTC.
  factory LiveEvent({
    required String type,
    required String eventId,
    required DateTime occurredAt,
    Map<String, Object?> payload = const {},
  }) {
    final trimmedType = type.trim();
    if (trimmedType.isEmpty) {
      throw ArgumentError.value(type, 'type', 'Event type must not be empty.');
    }
    final trimmedEventId = eventId.trim();
    if (trimmedEventId.isEmpty) {
      throw ArgumentError.value(
        eventId,
        'eventId',
        'eventId must not be empty.',
      );
    }

    return LiveEvent._(
      type: trimmedType,
      eventId: trimmedEventId,
      occurredAt: occurredAt.toUtc(),
      payload: _freezeJsonMap(payload),
    );
  }

  /// Decodes and validates a [LiveEvent] from JSON.
  factory LiveEvent.fromJson(Map<String, Object?> json) {
    final type = switch (json['type']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'type',
        'Expected a string event type.',
      ),
    };
    final eventId = switch (json['eventId']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'eventId',
        'Expected a string eventId.',
      ),
    };
    final occurredAt = _parseIso8601Utc(json['occurredAt'], 'occurredAt');
    final payload = switch (json['payload']) {
      null => const <String, Object?>{},
      final Map<String, Object?> map => map,
      final other => throw ArgumentError.value(
        other,
        'payload',
        'Expected a JSON object for payload.',
      ),
    };

    return LiveEvent(
      type: type,
      eventId: eventId,
      occurredAt: occurredAt,
      payload: payload,
    );
  }

  /// Serializes this live event to JSON.
  Map<String, Object?> toJson() => {
    'type': type,
    'eventId': eventId,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    if (payload.isNotEmpty) 'payload': payload,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! LiveEvent ||
        other.type != type ||
        other.eventId != eventId ||
        other.occurredAt != occurredAt) {
      return false;
    }
    return _deepMapEquals(payload, other.payload);
  }

  @override
  int get hashCode =>
      Object.hash(type, eventId, occurredAt, _deepValueHash(payload));
}
