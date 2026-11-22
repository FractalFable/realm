import 'package:meta/meta.dart';

import 'uri_validation.dart';

/// Client-side backend endpoint pointer resolved from runtime/build config.
///
/// Enforces HTTPS outside local loopback (`localhost`, `127.0.0.1`, `::1`)
/// unless `allowInsecureHttp` is explicitly enabled.
@immutable
class ClientEndpointConfig({
  required final Uri apiBaseUrl,
  bool allowInsecureHttp = false,
}) {
  this {
    validateHttpUri(
      apiBaseUrl,
      'apiBaseUrl',
      allowFragment: false,
      allowQuery: false,
      requireHttpsOutsideLoopback: !allowInsecureHttp,
    );
  }

  /// Decodes a [ClientEndpointConfig] from `/config.json` or
  /// `--dart-define-from-file` JSON.
  factory ClientEndpointConfig.fromJson(
    Map<String, Object?> json, {
    bool allowInsecureHttp = false,
  }) {
    final rawUrl = switch (json['apiBaseUrl']) {
      final String value when value.trim().isNotEmpty => value,
      final other => throw ArgumentError.value(
        other,
        'apiBaseUrl',
        'Expected a non-empty apiBaseUrl string.',
      ),
    };

    return ClientEndpointConfig(
      apiBaseUrl: parseHttpUri(
        rawUrl,
        'apiBaseUrl',
        allowFragment: false,
        allowQuery: false,
        requireHttpsOutsideLoopback: !allowInsecureHttp,
      ),
      allowInsecureHttp: allowInsecureHttp,
    );
  }

  /// Resolves the active backend URL in precedence order:
  /// 1. [explicitOverride] (for example, CLI/QR/local onboarding)
  /// 2. [configJson] containing a non-empty `apiBaseUrl` (runtime
  ///    `/config.json` or `--dart-define-from-file`)
  /// 3. [webOrigin] same-origin fallback for hosted web deployments
  factory ClientEndpointConfig.resolve({
    Uri? explicitOverride,
    Map<String, Object?>? configJson,
    Uri? webOrigin,
    bool allowInsecureHttp = false,
  }) {
    if (explicitOverride != null) {
      return ClientEndpointConfig(
        apiBaseUrl: explicitOverride,
        allowInsecureHttp: allowInsecureHttp,
      );
    }
    if (configJson != null) {
      final rawConfigUrl = configJson['apiBaseUrl'];
      final isBlankString =
          rawConfigUrl is String && rawConfigUrl.trim().isEmpty;
      if (rawConfigUrl != null && !isBlankString) {
        return ClientEndpointConfig.fromJson(
          configJson,
          allowInsecureHttp: allowInsecureHttp,
        );
      }
    }
    if (webOrigin != null) {
      return ClientEndpointConfig(
        apiBaseUrl: webOrigin,
        allowInsecureHttp: allowInsecureHttp,
      );
    }
    throw StateError(
      'No backend apiBaseUrl configured. Provide explicitOverride, '
      'configJson["apiBaseUrl"], or webOrigin.',
    );
  }

  static final RegExp _whitespacePattern = RegExp(r'\s');

  /// Resolves [relativePath] against [apiBaseUrl], preserving any base path
  /// prefix and rejecting scheme overrides, userinfo, fragments, whitespace,
  /// or parent-directory traversal (`..`).
  Uri endpoint(String relativePath) {
    if (_whitespacePattern.hasMatch(relativePath)) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Endpoint path must not contain whitespace.',
      );
    }
    final cleaned = relativePath.replaceFirst(RegExp('^/+'), '');
    final reference = Uri.tryParse(cleaned);
    if (reference == null ||
        reference.hasScheme ||
        reference.hasAuthority ||
        reference.hasFragment ||
        reference.pathSegments.contains('..')) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Endpoint path must be a relative path under apiBaseUrl.',
      );
    }

    final base = apiBaseUrl.path.endsWith('/')
        ? apiBaseUrl
        : apiBaseUrl.replace(path: '${apiBaseUrl.path}/');
    final resolved = base.resolveUri(reference);
    if (resolved.scheme != apiBaseUrl.scheme ||
        resolved.host != apiBaseUrl.host ||
        resolved.port != apiBaseUrl.port ||
        !resolved.path.startsWith(base.path)) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Endpoint path must stay within apiBaseUrl.',
      );
    }
    validateHttpUri(resolved, 'relativePath', allowFragment: false);
    return resolved;
  }

  /// Serializes this endpoint config to JSON.
  Map<String, Object?> toJson() => {'apiBaseUrl': apiBaseUrl.toString()};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientEndpointConfig && other.apiBaseUrl == apiBaseUrl;

  @override
  int get hashCode => apiBaseUrl.hashCode;

  @override
  String toString() => 'ClientEndpointConfig(apiBaseUrl: $apiBaseUrl)';
}
