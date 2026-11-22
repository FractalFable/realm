import 'package:meta/meta.dart';

import 'http_method.dart';

/// Function that decodes a typed payload from a JSON object.
typedef JsonDecoder<T> = T Function(Map<String, Object?> json);

/// Function that encodes a typed payload into a JSON object.
typedef JsonEncoder<T> = Map<String, Object?> Function(T value);

/// Marker payload for endpoints with an empty request or response body.
@immutable
final class EmptyPayload {
  /// Creates an [EmptyPayload].
  const EmptyPayload();

  /// Decodes an [EmptyPayload] from any JSON map.
  factory EmptyPayload.fromJson(Map<String, Object?> _) => const EmptyPayload();

  /// Serializes this payload as an empty JSON object.
  Map<String, Object?> toJson() => const {};

  @override
  bool operator ==(Object other) => other is EmptyPayload;

  @override
  int get hashCode => (EmptyPayload).hashCode;

  @override
  String toString() => 'EmptyPayload()';
}

/// Typed wire contract for a single HTTP API endpoint shared by Realm servers
/// and clients.
@immutable
final class Endpoint<Req, Res> {
  /// Creates a typed [Endpoint] descriptor.
  const Endpoint(
    this.path, {
    required this.method,
    required this.decodeRequest,
    required this.encodeRequest,
    required this.decodeResponse,
    required this.encodeResponse,
    this.requiresAuth = true,
  }) : assert(path != '', 'Endpoint path must not be empty.');

  /// Creates a `GET` [Endpoint] descriptor.
  const Endpoint.get(
    String path, {
    required JsonDecoder<Req> decodeRequest,
    required JsonEncoder<Req> encodeRequest,
    required JsonDecoder<Res> decodeResponse,
    required JsonEncoder<Res> encodeResponse,
    bool requiresAuth = true,
  }) : this(
         path,
         method: HttpMethod.get,
         decodeRequest: decodeRequest,
         encodeRequest: encodeRequest,
         decodeResponse: decodeResponse,
         encodeResponse: encodeResponse,
         requiresAuth: requiresAuth,
       );

  /// Creates a `POST` [Endpoint] descriptor.
  const Endpoint.post(
    String path, {
    required JsonDecoder<Req> decodeRequest,
    required JsonEncoder<Req> encodeRequest,
    required JsonDecoder<Res> decodeResponse,
    required JsonEncoder<Res> encodeResponse,
    bool requiresAuth = true,
  }) : this(
         path,
         method: HttpMethod.post,
         decodeRequest: decodeRequest,
         encodeRequest: encodeRequest,
         decodeResponse: decodeResponse,
         encodeResponse: encodeResponse,
         requiresAuth: requiresAuth,
       );

  /// Creates a `PUT` [Endpoint] descriptor.
  const Endpoint.put(
    String path, {
    required JsonDecoder<Req> decodeRequest,
    required JsonEncoder<Req> encodeRequest,
    required JsonDecoder<Res> decodeResponse,
    required JsonEncoder<Res> encodeResponse,
    bool requiresAuth = true,
  }) : this(
         path,
         method: HttpMethod.put,
         decodeRequest: decodeRequest,
         encodeRequest: encodeRequest,
         decodeResponse: decodeResponse,
         encodeResponse: encodeResponse,
         requiresAuth: requiresAuth,
       );

  /// Creates a `PATCH` [Endpoint] descriptor.
  const Endpoint.patch(
    String path, {
    required JsonDecoder<Req> decodeRequest,
    required JsonEncoder<Req> encodeRequest,
    required JsonDecoder<Res> decodeResponse,
    required JsonEncoder<Res> encodeResponse,
    bool requiresAuth = true,
  }) : this(
         path,
         method: HttpMethod.patch,
         decodeRequest: decodeRequest,
         encodeRequest: encodeRequest,
         decodeResponse: decodeResponse,
         encodeResponse: encodeResponse,
         requiresAuth: requiresAuth,
       );

  /// Creates a `DELETE` [Endpoint] descriptor.
  const Endpoint.delete(
    String path, {
    required JsonDecoder<Req> decodeRequest,
    required JsonEncoder<Req> encodeRequest,
    required JsonDecoder<Res> decodeResponse,
    required JsonEncoder<Res> encodeResponse,
    bool requiresAuth = true,
  }) : this(
         path,
         method: HttpMethod.delete,
         decodeRequest: decodeRequest,
         encodeRequest: encodeRequest,
         decodeResponse: decodeResponse,
         encodeResponse: encodeResponse,
         requiresAuth: requiresAuth,
       );

  static final RegExp _paramPattern = RegExp(':([A-Za-z_][A-Za-z0-9_]*)');

  /// Path template starting with `/` (e.g. `/api/v1/blobs/:blobId`).
  final String path;

  /// HTTP method for this endpoint.
  final HttpMethod method;

  /// Decoder for incoming request payloads on the server.
  final JsonDecoder<Req> decodeRequest;

  /// Encoder for outgoing request payloads on the client.
  // Contract fields keep exact Req/Res types and are never widened covariantly.
  // ignore: unsafe_variance
  final JsonEncoder<Req> encodeRequest;

  /// Decoder for incoming response payloads on the client.
  final JsonDecoder<Res> decodeResponse;

  /// Encoder for outgoing response payloads on the server.
  // Contract fields keep exact Req/Res types and are never widened covariantly.
  // ignore: unsafe_variance
  final JsonEncoder<Res> encodeResponse;

  /// Whether this endpoint requires an authenticated session.
  final bool requiresAuth;

  /// Substitutes `:name` path segments using URL-encoded values from [params].
  String resolvePath([Map<String, String> params = const {}]) {
    if (!path.startsWith('/')) {
      throw ArgumentError.value(
        path,
        'path',
        'Endpoint path must start with "/".',
      );
    }
    return path.replaceAllMapped(_paramPattern, (match) {
      final name = match.group(1)!;
      final value = params[name];
      if (value == null || value.trim().isEmpty) {
        throw ArgumentError.value(
          params,
          'params',
          'Missing non-empty path parameter "$name" for $path.',
        );
      }
      return Uri.encodeComponent(value);
    });
  }
}
