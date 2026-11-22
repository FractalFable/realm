import 'package:meta/meta.dart';

import 'api_error.dart';

/// Standard typed result alias for Realm API calls.
typedef ApiResult<T> = Result<T, ApiError>;

/// Pure-Dart discriminated union representing either success ([Ok]) or failure
/// ([Err]) without throwing expected wire errors.
@immutable
sealed class Result<T, E> {
  const Result();

  /// Whether this result holds an [Ok] value.
  bool get isOk => this is Ok<T, E>;

  /// Whether this result holds an [Err] error.
  bool get isErr => this is Err<T, E>;

  /// Returns the success value if [Ok], or `null` if [Err].
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// Returns the error value if [Err], or `null` if [Ok].
  E? get errorOrNull => switch (this) {
    Ok() => null,
    Err(:final error) => error,
  };

  /// Transforms the success value when [Ok], preserving [Err] untouched.
  Result<U, E> map<U>(U Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok<U, E>(transform(value)),
    Err(:final error) => Err<U, E>(error),
  };

  /// Transforms the error value when [Err], preserving [Ok] untouched.
  Result<T, F> mapError<F>(F Function(E error) transform) => switch (this) {
    Ok(:final value) => Ok<T, F>(value),
    Err(:final error) => Err<T, F>(transform(error)),
  };

  /// Exhaustively handles both [Ok] and [Err] branches.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(E error) onErr,
  }) => switch (this) {
    Ok(:final value) => onOk(value),
    Err(:final error) => onErr(error),
  };
}

/// Successful [Result] carrying [value].
@immutable
final class Ok<T, E> extends Result<T, E> {
  /// Creates an [Ok] result with [value].
  const Ok(this.value);

  /// The encapsulated success value.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T, E> && other.value == value);

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// Failed [Result] carrying [error].
@immutable
final class Err<T, E> extends Result<T, E> {
  /// Creates an [Err] result with [error].
  const Err(this.error);

  /// The encapsulated error value.
  final E error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Err<T, E> && other.error == error);

  @override
  int get hashCode => Object.hash(Err, error);

  @override
  String toString() => 'Err($error)';
}
