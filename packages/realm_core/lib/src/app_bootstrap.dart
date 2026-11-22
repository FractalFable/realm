import 'package:meta/meta.dart';

import 'app_branding.dart';

/// App-neutral non-secret capability flags computed server-side from configured
/// BYOK keys and enabled app modules.
@immutable
class const AppCapabilities._({
  required final bool aiAssistantEnabled,
  required final Set<String> enabledModules,
}) {
  /// Creates and validates an [AppCapabilities] payload.
  factory AppCapabilities({
    bool aiAssistantEnabled = false,
    Set<String> enabledModules = const {},
  }) {
    final normalized = <String>{};
    for (final module in enabledModules) {
      final trimmed = module.trim();
      if (trimmed.isEmpty) {
        throw ArgumentError.value(
          module,
          'enabledModules',
          'Module identifiers must not be empty or whitespace.',
        );
      }
      normalized.add(trimmed);
    }
    return AppCapabilities._(
      aiAssistantEnabled: aiAssistantEnabled,
      enabledModules: Set.unmodifiable(normalized),
    );
  }

  /// Decodes and validates an [AppCapabilities] payload from JSON.
  factory AppCapabilities.fromJson(Map<String, Object?> json) {
    final aiAssistantEnabled = switch (json['aiAssistantEnabled']) {
      null => false,
      final bool value => value,
      final other => throw ArgumentError.value(
        other,
        'aiAssistantEnabled',
        'Expected a boolean value.',
      ),
    };
    final enabledModules = switch (json['enabledModules']) {
      null => <String>{},
      final List<Object?> items => {
        for (final item in items)
          switch (item) {
            final String value => value,
            final other => throw ArgumentError.value(
              other,
              'enabledModules',
              'Expected string module identifiers.',
            ),
          },
      },
      final other => throw ArgumentError.value(
        other,
        'enabledModules',
        'Expected a list of module identifier strings.',
      ),
    };

    return AppCapabilities(
      aiAssistantEnabled: aiAssistantEnabled,
      enabledModules: enabledModules,
    );
  }

  /// Whether a module identifier is enabled on the backend.
  bool supportsModule(String module) => enabledModules.contains(module);

  /// Serializes these capability flags to JSON.
  Map<String, Object?> toJson() {
    final sortedModules = enabledModules.toList()..sort();
    return {
      'aiAssistantEnabled': aiAssistantEnabled,
      if (sortedModules.isNotEmpty) 'enabledModules': sortedModules,
    };
  }

  /// Returns a copy of these capabilities with the given fields updated.
  AppCapabilities copyWith({
    bool? aiAssistantEnabled,
    Set<String>? enabledModules,
  }) => AppCapabilities(
    aiAssistantEnabled: aiAssistantEnabled ?? this.aiAssistantEnabled,
    enabledModules: enabledModules ?? this.enabledModules,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! AppCapabilities ||
        other.aiAssistantEnabled != aiAssistantEnabled ||
        other.enabledModules.length != enabledModules.length) {
      return false;
    }
    return enabledModules.containsAll(other.enabledModules);
  }

  @override
  int get hashCode =>
      Object.hash(aiAssistantEnabled, Object.hashAllUnordered(enabledModules));

  @override
  String toString() {
    final sorted = enabledModules.toList()..sort();
    return 'AppCapabilities(aiAssistantEnabled: $aiAssistantEnabled, '
        'enabledModules: $sorted)';
  }
}

/// App-neutral bootstrap contract returned by `GET /api/v1/bootstrap`.
@immutable
class AppBootstrap({
  required final AppBranding branding,
  final AppCapabilities capabilities = const AppCapabilities._(
    aiAssistantEnabled: false,
    enabledModules: {},
  ),
  final HostingMode hostingMode = .selfHosted,
}) {
  /// Decodes and validates an [AppBootstrap] payload from JSON.
  factory AppBootstrap.fromJson(Map<String, Object?> json) {
    final branding = switch (json['branding']) {
      final Map<String, Object?> map => AppBranding.fromJson(map),
      final other => throw ArgumentError.value(
        other,
        'branding',
        'Expected a branding JSON object.',
      ),
    };
    final capabilities = switch (json['capabilities']) {
      null => AppCapabilities(),
      final Map<String, Object?> map => AppCapabilities.fromJson(map),
      final other => throw ArgumentError.value(
        other,
        'capabilities',
        'Expected a capabilities JSON object.',
      ),
    };
    final hostingMode = switch (json['hostingMode']) {
      null => HostingMode.selfHosted,
      final String value => HostingMode.fromName(value),
      final other => throw ArgumentError.value(
        other,
        'hostingMode',
        'Expected a hostingMode string.',
      ),
    };

    return AppBootstrap(
      branding: branding,
      capabilities: capabilities,
      hostingMode: hostingMode,
    );
  }

  /// Serializes this bootstrap payload to JSON.
  Map<String, Object?> toJson() => {
    'branding': branding.toJson(),
    'capabilities': capabilities.toJson(),
    'hostingMode': hostingMode.name,
  };

  /// Returns a copy of this bootstrap payload with the given fields updated.
  AppBootstrap copyWith({
    AppBranding? branding,
    AppCapabilities? capabilities,
    HostingMode? hostingMode,
  }) => AppBootstrap(
    branding: branding ?? this.branding,
    capabilities: capabilities ?? this.capabilities,
    hostingMode: hostingMode ?? this.hostingMode,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBootstrap &&
          other.branding == branding &&
          other.capabilities == capabilities &&
          other.hostingMode == hostingMode;

  @override
  int get hashCode => Object.hash(branding, capabilities, hostingMode);

  @override
  String toString() =>
      'AppBootstrap(branding: $branding, capabilities: $capabilities, '
      'hostingMode: $hostingMode)';
}
