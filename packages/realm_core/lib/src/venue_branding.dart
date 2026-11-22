import 'package:meta/meta.dart';

import 'app_branding.dart';
import 'uri_validation.dart';

export 'app_branding.dart' show HostingMode;

/// Operator-supplied branding configuration for a venue.
///
/// Extends [AppBranding] so venue branding works seamlessly with shared
/// `realm_ui` theming while preserving Tavern compatibility.
@immutable
class VenueBranding extends AppBranding {
  /// Creates and validates a [VenueBranding].
  VenueBranding({
    required super.name,
    required super.primaryColorArgb,
    super.tagline,
    super.logoUrl,
  });

  /// Decodes and validates a [VenueBranding] from JSON.
  factory VenueBranding.fromJson(Map<String, Object?> json) {
    final decoded = AppBranding.fromJson(json);
    return VenueBranding(
      name: decoded.name,
      primaryColorArgb: decoded.primaryColorArgb,
      tagline: decoded.tagline,
      logoUrl: decoded.logoUrl,
    );
  }

  @override
  VenueBranding copyWith({
    String? name,
    int? primaryColorArgb,
    String? Function()? tagline,
    Uri? Function()? logoUrl,
  }) => VenueBranding(
    name: name ?? this.name,
    primaryColorArgb: primaryColorArgb ?? this.primaryColorArgb,
    tagline: tagline != null ? tagline() : this.tagline,
    logoUrl: logoUrl != null ? logoUrl() : this.logoUrl,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VenueBranding &&
          other.name == name &&
          other.primaryColorArgb == primaryColorArgb &&
          other.tagline == tagline &&
          other.logoUrl == logoUrl;

  @override
  int get hashCode =>
      Object.hash(runtimeType, name, primaryColorArgb, tagline, logoUrl);

  @override
  String toString() =>
      'VenueBranding(name: $name, primaryColorArgb: $primaryColorArgb, '
      'tagline: $tagline, logoUrl: $logoUrl)';
}

/// Top-level runtime configuration for a self-hosted or managed venue.
@immutable
class VenueConfig extends AppConfig {
  /// Creates and validates a [VenueConfig].
  VenueConfig({
    required VenueBranding super.branding,
    super.hostingMode = .selfHosted,
    super.apiBaseUrl,
  });

  /// Decodes and validates a [VenueConfig] from JSON.
  factory VenueConfig.fromJson(Map<String, Object?> json) {
    final branding = switch (json['branding']) {
      final Map<String, Object?> map => VenueBranding.fromJson(map),
      final other => throw ArgumentError.value(
        other,
        'branding',
        'Expected a branding JSON object.',
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
    final apiBaseUrl = switch (json['apiBaseUrl']) {
      null => null,
      final String value => parseHttpUri(
        value,
        'apiBaseUrl',
        allowFragment: false,
        allowQuery: false,
      ),
      final other => throw ArgumentError.value(
        other,
        'apiBaseUrl',
        'Expected a URI string or null apiBaseUrl.',
      ),
    };

    return VenueConfig(
      branding: branding,
      hostingMode: hostingMode,
      apiBaseUrl: apiBaseUrl,
    );
  }

  @override
  VenueBranding get branding => super.branding as VenueBranding;

  @override
  VenueConfig copyWith({
    covariant VenueBranding? branding,
    HostingMode? hostingMode,
    Uri? Function()? apiBaseUrl,
  }) => VenueConfig(
    branding: branding ?? this.branding,
    hostingMode: hostingMode ?? this.hostingMode,
    apiBaseUrl: apiBaseUrl != null ? apiBaseUrl() : this.apiBaseUrl,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VenueConfig &&
          other.branding == branding &&
          other.hostingMode == hostingMode &&
          other.apiBaseUrl == apiBaseUrl;

  @override
  int get hashCode =>
      Object.hash(runtimeType, branding, hostingMode, apiBaseUrl);

  @override
  String toString() =>
      'VenueConfig(branding: $branding, hostingMode: $hostingMode, '
      'apiBaseUrl: $apiBaseUrl)';
}
