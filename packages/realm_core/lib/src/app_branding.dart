import 'package:meta/meta.dart';

import 'uri_validation.dart';

/// Supported deployment topologies for a Realm application instance.
enum HostingMode {
  selfHosted,
  managed;

  /// Parses a [HostingMode] from its JSON [name].
  static HostingMode fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError.value(name, 'hostingMode', 'Unknown hosting mode.');
  }
}

/// Operator-supplied white-label branding configuration for a Realm app.
@immutable
class AppBranding({
  required final String name,
  required final int primaryColorArgb,
  final String? tagline,
  final Uri? logoUrl,
}) {
  this {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'App name must not be empty or whitespace.',
      );
    }
    if (primaryColorArgb < 0 ||
        primaryColorArgb > 0xFFFFFFFF ||
        (primaryColorArgb & 0xFF000000) == 0) {
      throw ArgumentError.value(
        primaryColorArgb,
        'primaryColorArgb',
        'Must be a 32-bit ARGB integer (0..0xFFFFFFFF) with non-zero alpha.',
      );
    }
    if (tagline case final value? when value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'tagline',
        'Tagline must not be empty or whitespace when provided.',
      );
    }
    if (logoUrl case final url?) {
      validateHttpUri(url, 'logoUrl');
    }
  }

  /// Decodes and validates an [AppBranding] from JSON.
  factory AppBranding.fromJson(Map<String, Object?> json) {
    final name = switch (json['name']) {
      final String value => value,
      _ => throw ArgumentError.value(
        json['name'],
        'name',
        'Expected a string app name.',
      ),
    };
    final primaryColorArgb = switch (json['primaryColorArgb']) {
      final int value => value,
      _ => throw ArgumentError.value(
        json['primaryColorArgb'],
        'primaryColorArgb',
        'Expected an integer ARGB color.',
      ),
    };
    final tagline = switch (json['tagline']) {
      null => null,
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'tagline',
        'Expected a string or null tagline.',
      ),
    };
    final logoUrl = switch (json['logoUrl']) {
      null => null,
      final String value => parseHttpUri(value, 'logoUrl'),
      final other => throw ArgumentError.value(
        other,
        'logoUrl',
        'Expected a URI string or null logoUrl.',
      ),
    };

    return AppBranding(
      name: name,
      primaryColorArgb: primaryColorArgb,
      tagline: tagline,
      logoUrl: logoUrl,
    );
  }

  /// Serializes this branding configuration to JSON.
  Map<String, Object?> toJson() => {
    'name': name,
    'primaryColorArgb': primaryColorArgb,
    'tagline': ?tagline,
    'logoUrl': ?logoUrl?.toString(),
  };

  /// Returns a copy of this branding with the given fields updated.
  AppBranding copyWith({
    String? name,
    int? primaryColorArgb,
    String? Function()? tagline,
    Uri? Function()? logoUrl,
  }) => AppBranding(
    name: name ?? this.name,
    primaryColorArgb: primaryColorArgb ?? this.primaryColorArgb,
    tagline: tagline != null ? tagline() : this.tagline,
    logoUrl: logoUrl != null ? logoUrl() : this.logoUrl,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBranding &&
          other.runtimeType == runtimeType &&
          other.name == name &&
          other.primaryColorArgb == primaryColorArgb &&
          other.tagline == tagline &&
          other.logoUrl == logoUrl;

  @override
  int get hashCode =>
      Object.hash(runtimeType, name, primaryColorArgb, tagline, logoUrl);

  @override
  String toString() =>
      'AppBranding(name: $name, primaryColorArgb: $primaryColorArgb, '
      'tagline: $tagline, logoUrl: $logoUrl)';
}

/// Top-level runtime configuration for a self-hosted or managed Realm app.
@immutable
class AppConfig({
  required final AppBranding branding,
  final HostingMode hostingMode = .selfHosted,
  final Uri? apiBaseUrl,
}) {
  this {
    if (apiBaseUrl case final url?) {
      validateHttpUri(
        url,
        'apiBaseUrl',
        allowFragment: false,
        allowQuery: false,
      );
    }
  }

  /// Decodes and validates an [AppConfig] from JSON.
  factory AppConfig.fromJson(Map<String, Object?> json) {
    final branding = switch (json['branding']) {
      final Map<String, Object?> map => AppBranding.fromJson(map),
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

    return AppConfig(
      branding: branding,
      hostingMode: hostingMode,
      apiBaseUrl: apiBaseUrl,
    );
  }

  /// Serializes this configuration to JSON.
  Map<String, Object?> toJson() => {
    'branding': branding.toJson(),
    'hostingMode': hostingMode.name,
    'apiBaseUrl': ?apiBaseUrl?.toString(),
  };

  /// Returns a copy of this configuration with the given fields updated.
  AppConfig copyWith({
    AppBranding? branding,
    HostingMode? hostingMode,
    Uri? Function()? apiBaseUrl,
  }) => AppConfig(
    branding: branding ?? this.branding,
    hostingMode: hostingMode ?? this.hostingMode,
    apiBaseUrl: apiBaseUrl != null ? apiBaseUrl() : this.apiBaseUrl,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          other.runtimeType == runtimeType &&
          other.branding == branding &&
          other.hostingMode == hostingMode &&
          other.apiBaseUrl == apiBaseUrl;

  @override
  int get hashCode =>
      Object.hash(runtimeType, branding, hostingMode, apiBaseUrl);

  @override
  String toString() =>
      'AppConfig(branding: $branding, hostingMode: $hostingMode, '
      'apiBaseUrl: $apiBaseUrl)';
}
