import 'package:meta/meta.dart';

/// Machine-readable wire error categories shared across Realm clients and
/// servers.
enum ApiErrorCode {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  validationFailed,
  internalError,
  serviceUnavailable,
  networkError;

  /// Parses an [ApiErrorCode] from its JSON [name].
  static ApiErrorCode fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError.value(name, 'code', 'Unknown ApiErrorCode.');
  }
}

/// Typed API error envelope returned across Realm endpoints.
@immutable
class const ApiError._({
  required final ApiErrorCode code,
  required final String message,
  required final Map<String, String> fieldErrors,
  final String? requestId,
}) {
  /// Creates and validates an [ApiError].
  factory ApiError({
    required ApiErrorCode code,
    required String message,
    Map<String, String> fieldErrors = const {},
    String? requestId,
  }) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw ArgumentError.value(
        message,
        'message',
        'Error message must not be empty.',
      );
    }

    final normalizedFields = <String, String>{};
    for (final MapEntry(:key, :value) in fieldErrors.entries) {
      final trimmedKey = key.trim();
      if (trimmedKey.isEmpty) {
        throw ArgumentError.value(
          key,
          'fieldErrors',
          'Field error keys must not be empty.',
        );
      }
      final trimmedValue = value.trim();
      if (trimmedValue.isEmpty) {
        throw ArgumentError.value(
          value,
          'fieldErrors',
          'Field error message for "$trimmedKey" must not be empty.',
        );
      }
      normalizedFields[trimmedKey] = trimmedValue;
    }

    String? normalizedRequestId;
    if (requestId != null) {
      final trimmed = requestId.trim();
      if (trimmed.isEmpty) {
        throw ArgumentError.value(
          requestId,
          'requestId',
          'requestId must not be empty when provided.',
        );
      }
      normalizedRequestId = trimmed;
    }

    return ApiError._(
      code: code,
      message: trimmedMessage,
      fieldErrors: Map.unmodifiable(normalizedFields),
      requestId: normalizedRequestId,
    );
  }

  /// Decodes and validates an [ApiError] from JSON.
  factory ApiError.fromJson(Map<String, Object?> json) {
    final code = switch (json['code']) {
      final String value => ApiErrorCode.fromName(value),
      final other => throw ArgumentError.value(
        other,
        'code',
        'Expected an ApiErrorCode string.',
      ),
    };
    final message = switch (json['message']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'message',
        'Expected a string message.',
      ),
    };
    final fieldErrors = switch (json['fieldErrors']) {
      null => const <String, String>{},
      final Map<Object?, Object?> rawMap => {
        for (final MapEntry(:key, :value) in rawMap.entries)
          switch (key) {
            final String k => k,
            final other => throw ArgumentError.value(
              other,
              'fieldErrors',
              'Expected string keys in fieldErrors.',
            ),
          }: switch (value) {
            final String v => v,
            final other => throw ArgumentError.value(
              other,
              'fieldErrors',
              'Expected string values in fieldErrors.',
            ),
          },
      },
      final other => throw ArgumentError.value(
        other,
        'fieldErrors',
        'Expected a JSON object for fieldErrors.',
      ),
    };
    final requestId = switch (json['requestId']) {
      null => null,
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'requestId',
        'Expected a string or null for requestId.',
      ),
    };

    return ApiError(
      code: code,
      message: message,
      fieldErrors: fieldErrors,
      requestId: requestId,
    );
  }

  /// Serializes this error to JSON.
  Map<String, Object?> toJson() => {
    'code': code.name,
    'message': message,
    if (fieldErrors.isNotEmpty) 'fieldErrors': fieldErrors,
    'requestId': ?requestId,
  };

  /// Returns a copy of this error with updated fields.
  ApiError copyWith({
    ApiErrorCode? code,
    String? message,
    Map<String, String>? fieldErrors,
    String? requestId,
  }) => ApiError(
    code: code ?? this.code,
    message: message ?? this.message,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    requestId: requestId ?? this.requestId,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ApiError ||
        other.code != code ||
        other.message != message ||
        other.requestId != requestId ||
        other.fieldErrors.length != fieldErrors.length) {
      return false;
    }
    for (final MapEntry(:key, :value) in fieldErrors.entries) {
      if (other.fieldErrors[key] != value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    code,
    message,
    requestId,
    Object.hashAllUnordered(
      fieldErrors.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'ApiError(code: ${code.name}, message: $message, '
      'fieldErrors: $fieldErrors, requestId: $requestId)';
}
