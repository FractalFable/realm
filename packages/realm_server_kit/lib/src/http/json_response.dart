import 'dart:convert';

import 'package:relic/relic.dart';

/// Builds a `200 OK` JSON [Response] with `application/json` content type.
Response jsonOk(Object? payload, {Headers? headers}) => Response.ok(
  body: Body.fromString(jsonEncode(payload), mimeType: MimeType.json),
  headers: headers,
);

/// Builds a structured JSON error [Response] with the given HTTP [statusCode],
/// machine-readable [code], and human-readable [message].
Response jsonError(
  int statusCode,
  String code,
  String message, {
  Headers? headers,
}) => Response(
  statusCode,
  body: Body.fromString(
    jsonEncode({'code': code, 'message': message}),
    mimeType: MimeType.json,
  ),
  headers: headers,
);
