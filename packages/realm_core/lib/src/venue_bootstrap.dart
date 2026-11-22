import 'package:meta/meta.dart';

import 'venue_branding.dart';
import 'venue_capabilities.dart';

/// Shared wire contract returned by `GET /api/v1/bootstrap` so client apps load
/// venue branding and active capabilities dynamically at runtime.
@immutable
class VenueBootstrap({
  required final VenueBranding branding,
  final VenueCapabilities capabilities = const VenueCapabilities(),
  final HostingMode hostingMode = .selfHosted,
}) {
  /// Decodes and validates a [VenueBootstrap] payload from JSON.
  factory VenueBootstrap.fromJson(Map<String, Object?> json) {
    final branding = switch (json['branding']) {
      final Map<String, Object?> map => VenueBranding.fromJson(map),
      final other => throw ArgumentError.value(
        other,
        'branding',
        'Expected a branding JSON object.',
      ),
    };
    final capabilities = switch (json['capabilities']) {
      null => const VenueCapabilities(),
      final Map<String, Object?> map => VenueCapabilities.fromJson(map),
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

    return VenueBootstrap(
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
  VenueBootstrap copyWith({
    VenueBranding? branding,
    VenueCapabilities? capabilities,
    HostingMode? hostingMode,
  }) => VenueBootstrap(
    branding: branding ?? this.branding,
    capabilities: capabilities ?? this.capabilities,
    hostingMode: hostingMode ?? this.hostingMode,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VenueBootstrap &&
          other.branding == branding &&
          other.capabilities == capabilities &&
          other.hostingMode == hostingMode;

  @override
  int get hashCode => Object.hash(branding, capabilities, hostingMode);

  @override
  String toString() =>
      'VenueBootstrap(branding: $branding, capabilities: $capabilities, '
      'hostingMode: $hostingMode)';
}
