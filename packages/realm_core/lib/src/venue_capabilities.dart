import 'package:meta/meta.dart';

bool _readBoolField(Map<String, Object?> json, String key) =>
    switch (json[key]) {
      null => false,
      final bool value => value,
      final other => throw ArgumentError.value(
        other,
        key,
        'Expected a boolean value.',
      ),
    };

/// Non-secret feature flags derived server-side from configured BYOK keys and
/// enabled integrations.
@immutable
class const VenueCapabilities({
  final bool aiAssistantEnabled = false,
  final bool onlineOrderingEnabled = false,
  final bool paymentsEnabled = false,
}) {
  /// Decodes a [VenueCapabilities] payload from JSON.
  factory VenueCapabilities.fromJson(Map<String, Object?> json) =>
      VenueCapabilities(
        aiAssistantEnabled: _readBoolField(json, 'aiAssistantEnabled'),
        onlineOrderingEnabled: _readBoolField(json, 'onlineOrderingEnabled'),
        paymentsEnabled: _readBoolField(json, 'paymentsEnabled'),
      );

  /// Serializes these capability flags to JSON.
  Map<String, Object?> toJson() => {
    'aiAssistantEnabled': aiAssistantEnabled,
    'onlineOrderingEnabled': onlineOrderingEnabled,
    'paymentsEnabled': paymentsEnabled,
  };

  /// Returns a copy of these capabilities with the given fields updated.
  VenueCapabilities copyWith({
    bool? aiAssistantEnabled,
    bool? onlineOrderingEnabled,
    bool? paymentsEnabled,
  }) => VenueCapabilities(
    aiAssistantEnabled: aiAssistantEnabled ?? this.aiAssistantEnabled,
    onlineOrderingEnabled: onlineOrderingEnabled ?? this.onlineOrderingEnabled,
    paymentsEnabled: paymentsEnabled ?? this.paymentsEnabled,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VenueCapabilities &&
          other.aiAssistantEnabled == aiAssistantEnabled &&
          other.onlineOrderingEnabled == onlineOrderingEnabled &&
          other.paymentsEnabled == paymentsEnabled;

  @override
  int get hashCode =>
      Object.hash(aiAssistantEnabled, onlineOrderingEnabled, paymentsEnabled);

  @override
  String toString() =>
      'VenueCapabilities(aiAssistantEnabled: $aiAssistantEnabled, '
      'onlineOrderingEnabled: $onlineOrderingEnabled, '
      'paymentsEnabled: $paymentsEnabled)';
}
