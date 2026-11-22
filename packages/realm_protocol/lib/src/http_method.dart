/// HTTP methods supported by typed `Endpoint` descriptors.
enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  const HttpMethod(this.wireName);

  /// Uppercase HTTP verb used on the wire.
  final String wireName;

  /// Parses an [HttpMethod] from its enum [name].
  static HttpMethod fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError.value(name, 'method', 'Unknown HttpMethod.');
  }

  /// Parses an [HttpMethod] from its uppercase HTTP [wireName].
  static HttpMethod fromWireName(String wireName) {
    for (final value in values) {
      if (value.wireName == wireName) {
        return value;
      }
    }
    throw ArgumentError.value(
      wireName,
      'wireName',
      'Unknown HTTP wire method.',
    );
  }
}
