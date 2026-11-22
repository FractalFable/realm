import 'package:meta/meta.dart';

/// Monetary amount represented strictly in integer minor units (e.g. cents)
/// paired with a 3-letter uppercase ISO 4217 [currencyCode].
@immutable
class Money({
  required final int minorUnits,
  required final String currencyCode,
}) {
  this {
    if (!_iso4217Pattern.hasMatch(currencyCode)) {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'Must be a 3-letter uppercase ISO 4217 currency code.',
      );
    }
  }

  /// Decodes and validates a [Money] value from JSON.
  factory Money.fromJson(Map<String, Object?> json) {
    final minorUnits = switch (json['minorUnits']) {
      final int value => value,
      final other => throw ArgumentError.value(
        other,
        'minorUnits',
        'Expected an integer minorUnits value.',
      ),
    };
    final currencyCode = switch (json['currencyCode']) {
      final String value => value,
      final other => throw ArgumentError.value(
        other,
        'currencyCode',
        'Expected an ISO 4217 currencyCode string.',
      ),
    };

    return Money(minorUnits: minorUnits, currencyCode: currencyCode);
  }

  static final RegExp _iso4217Pattern = RegExp(r'^[A-Z]{3}$');

  /// Adds two [Money] amounts of the same currency.
  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(
      minorUnits: minorUnits + other.minorUnits,
      currencyCode: currencyCode,
    );
  }

  /// Subtracts [other] from this amount in the same currency.
  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(
      minorUnits: minorUnits - other.minorUnits,
      currencyCode: currencyCode,
    );
  }

  void _requireSameCurrency(Money other) {
    if (other.currencyCode != currencyCode) {
      throw ArgumentError.value(
        other.currencyCode,
        'currencyCode',
        'Currency mismatch: expected $currencyCode, got ${other.currencyCode}.',
      );
    }
  }

  /// Serializes this monetary amount to JSON.
  Map<String, Object?> toJson() => {
    'minorUnits': minorUnits,
    'currencyCode': currencyCode,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          other.minorUnits == minorUnits &&
          other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);

  @override
  String toString() => 'Money($minorUnits $currencyCode)';
}
