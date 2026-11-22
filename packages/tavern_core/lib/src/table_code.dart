import 'package:meta/meta.dart';

/// Unguessable URL-safe QR table code (`>= 12` characters from `[A-Za-z0-9_-]`)
/// used in `/t/<table-code>` links.
@immutable
class TableCode({required final String value}) {
  this {
    if (_digitsOnlyPattern.hasMatch(value) || !_pattern.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'Table code must be 12..64 URL-safe characters and not numeric-only.',
      );
    }
  }

  /// Decodes and validates a [TableCode] from a JSON string.
  factory TableCode.fromJson(Object? json) => switch (json) {
    final String raw => TableCode(value: raw),
    final other => throw ArgumentError.value(
      other,
      'tableCode',
      'Expected a string table code.',
    ),
  };

  static final RegExp _pattern = RegExp(r'^[A-Za-z0-9_-]{12,64}$');
  static final RegExp _digitsOnlyPattern = RegExp(r'^\d+$');

  /// Serializes this table code as a string.
  String toJson() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TableCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TableCode($value)';
}
