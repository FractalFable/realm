final RegExp _whitespacePattern = RegExp(r'\s');
final RegExp _encodedWhitespacePattern = RegExp(
  '%(?:09|0[aAdD]|20)',
  caseSensitive: false,
);

bool _isLoopbackHost(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '::1';
}

bool _hasAtInAuthority(String raw) {
  final schemeEnd = raw.indexOf('://');
  if (schemeEnd == -1) {
    return false;
  }
  final afterScheme = raw.substring(schemeEnd + 3);
  final authorityEnd = afterScheme.indexOf(RegExp('[/?#]'));
  final authority = authorityEnd == -1
      ? afterScheme
      : afterScheme.substring(0, authorityEnd);
  return authority.contains('@');
}

/// Validates that [uri] is an absolute `http` or `https` URI with a non-empty
/// host, valid port (if specified), and no embedded userinfo.
void validateHttpUri(
  Uri uri,
  String name, {
  bool allowFragment = true,
  bool allowQuery = true,
  bool requireHttpsOutsideLoopback = false,
}) {
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw ArgumentError.value(uri, name, 'Must use an http or https scheme.');
  }
  if (!uri.hasAuthority || uri.host.isEmpty) {
    throw ArgumentError.value(uri, name, 'Must include a non-empty host.');
  }
  if (requireHttpsOutsideLoopback &&
      uri.scheme != 'https' &&
      !_isLoopbackHost(uri.host)) {
    throw ArgumentError.value(
      uri,
      name,
      'HTTPS is required outside local loopback.',
    );
  }
  if (_encodedWhitespacePattern.hasMatch(uri.host)) {
    throw ArgumentError.value(uri, name, 'Host must not contain whitespace.');
  }
  if (uri.userInfo.isNotEmpty || _hasAtInAuthority(uri.toString())) {
    throw ArgumentError.value(uri, name, 'Must not include userinfo.');
  }
  if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
    throw ArgumentError.value(uri, name, 'Port must be between 1 and 65535.');
  }
  if (!allowQuery && uri.hasQuery) {
    throw ArgumentError.value(uri, name, 'Must not include a query string.');
  }
  if (!allowFragment && uri.hasFragment) {
    throw ArgumentError.value(uri, name, 'Must not include a fragment.');
  }
}

/// Parses [raw] and validates it with [validateHttpUri].
Uri parseHttpUri(
  String raw,
  String name, {
  bool allowFragment = true,
  bool allowQuery = true,
  bool requireHttpsOutsideLoopback = false,
}) {
  if (raw.trim().isEmpty || _whitespacePattern.hasMatch(raw)) {
    throw ArgumentError.value(
      raw,
      name,
      'Must not be empty or contain whitespace.',
    );
  }
  if (_hasAtInAuthority(raw)) {
    throw ArgumentError.value(raw, name, 'Must not include userinfo.');
  }
  final parsed = Uri.tryParse(raw);
  if (parsed == null) {
    throw ArgumentError.value(raw, name, 'Must be a valid URI.');
  }
  validateHttpUri(
    parsed,
    name,
    allowFragment: allowFragment,
    allowQuery: allowQuery,
    requireHttpsOutsideLoopback: requireHttpsOutsideLoopback,
  );
  return parsed;
}
