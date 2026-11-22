import 'package:meta/meta.dart';

/// Supported deployment topologies for a Realm venue instance.
enum HostingMode { selfHosted, managed }

void _validateHttpUri(Uri uri, String name, {bool allowFragment = true}) {
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw ArgumentError.value(uri, name, 'Must use an http or https scheme.');
  }
  if (!uri.hasAuthority || uri.host.isEmpty) {
    throw ArgumentError.value(uri, name, 'Must include a non-empty host.');
  }
  if (uri.userInfo.isNotEmpty) {
    throw ArgumentError.value(uri, name, 'Must not include userinfo.');
  }
  if (!allowFragment && uri.hasFragment) {
    throw ArgumentError.value(uri, name, 'Must not include a fragment.');
  }
}

/// Operator-supplied branding configuration for a venue.
@immutable
class VenueBranding({
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
        'Venue name must not be empty or whitespace.',
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
      _validateHttpUri(url, 'logoUrl');
    }
  }

  /// Returns a copy of this branding with the given fields updated.
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
  int get hashCode => Object.hash(name, primaryColorArgb, tagline, logoUrl);

  @override
  String toString() =>
      'VenueBranding(name: $name, primaryColorArgb: $primaryColorArgb, '
      'tagline: $tagline, logoUrl: $logoUrl)';
}

/// Top-level runtime configuration for a self-hosted or managed venue.
@immutable
class VenueConfig({
  required final VenueBranding branding,
  final HostingMode hostingMode = .selfHosted,
  final Uri? apiBaseUrl,
}) {
  this {
    if (apiBaseUrl case final url?) {
      _validateHttpUri(url, 'apiBaseUrl', allowFragment: false);
    }
  }

  /// Returns a copy of this configuration with the given fields updated.
  VenueConfig copyWith({
    VenueBranding? branding,
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
  int get hashCode => Object.hash(branding, hostingMode, apiBaseUrl);

  @override
  String toString() =>
      'VenueConfig(branding: $branding, hostingMode: $hostingMode, '
      'apiBaseUrl: $apiBaseUrl)';
}
