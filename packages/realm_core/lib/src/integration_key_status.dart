import 'package:meta/meta.dart';

/// Supported external integration categories that accept operator BYOK keys.
enum IntegrationProvider {
  aiLlm,
  payments,
  posFiscal,
  email,
  sms;

  /// Parses an [IntegrationProvider] from its JSON [name].
  static IntegrationProvider fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError(
      'Unknown integration provider (length=${name.length}).',
      'provider',
    );
  }
}

/// Storage source backing an operator integration credential on the backend.
enum KeySource {
  unconfigured,
  environment,
  encryptedVault;

  /// Parses a [KeySource] from its JSON [name].
  static KeySource fromName(String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw ArgumentError(
      'Unknown key source (length=${name.length}).',
      'source',
    );
  }
}

/// Non-secret Admin UI DTO describing whether a BYOK provider is configured.
///
/// Full API keys never leave the backend. [keyHint] only permits masked short
/// suffixes (`...` or `***` followed by 1..4 visible printable ASCII chars);
/// backends must generate hints server-side only for secrets of at least 16
/// characters and never accept client-supplied hints.
@immutable
class IntegrationKeyStatus._({
  required final IntegrationProvider provider,
  final KeySource source = .unconfigured,
  final String? keyHint,
  final DateTime? updatedAt,
}) {
  /// Creates and validates an [IntegrationKeyStatus], normalizing [updatedAt]
  /// to UTC.
  factory IntegrationKeyStatus({
    required IntegrationProvider provider,
    KeySource source = .unconfigured,
    String? keyHint,
    DateTime? updatedAt,
  }) {
    if (source == .unconfigured) {
      if (keyHint != null) {
        throw ArgumentError(
          'Unconfigured integrations must not define a keyHint.',
          'keyHint',
        );
      }
      if (updatedAt != null) {
        throw ArgumentError.value(
          updatedAt,
          'updatedAt',
          'Unconfigured integrations must not define updatedAt.',
        );
      }
    }
    if (keyHint != null && !_maskedHintPattern.hasMatch(keyHint)) {
      throw ArgumentError(
        'Invalid keyHint (length=${keyHint.length}); '
            'expected masked suffix such as "...a1b2".',
        'keyHint',
      );
    }

    return IntegrationKeyStatus._(
      provider: provider,
      source: source,
      keyHint: keyHint,
      updatedAt: updatedAt?.toUtc(),
    );
  }

  /// Decodes and validates an [IntegrationKeyStatus] from JSON.
  factory IntegrationKeyStatus.fromJson(Map<String, Object?> json) {
    final provider = switch (json['provider']) {
      final String value => IntegrationProvider.fromName(value),
      final other => throw ArgumentError(
        'Expected an integration provider string (got ${other.runtimeType}).',
        'provider',
      ),
    };
    final source = switch (json['source']) {
      null => KeySource.unconfigured,
      final String value => KeySource.fromName(value),
      final other => throw ArgumentError(
        'Expected a key source string (got ${other.runtimeType}).',
        'source',
      ),
    };
    final keyHint = switch (json['keyHint']) {
      null => null,
      final String value => value,
      final other => throw ArgumentError(
        'Expected a string or null keyHint (got ${other.runtimeType}).',
        'keyHint',
      ),
    };
    final updatedAt = switch (json['updatedAt']) {
      null => null,
      final String value => _parseIso8601Utc(value),
      final other => throw ArgumentError(
        'Expected an ISO-8601 timestamp string or null '
            '(got ${other.runtimeType}).',
        'updatedAt',
      ),
    };

    return IntegrationKeyStatus(
      provider: provider,
      source: source,
      keyHint: keyHint,
      updatedAt: updatedAt,
    );
  }

  static final RegExp _maskedHintPattern = RegExp(
    r'^(?:\.{3}|\*{3})[\x21-\x7E]{1,4}$',
  );
  static final RegExp _isoTimezonePattern = RegExp(
    r'(?:Z|[+-]\d{2}:?\d{2})$',
    caseSensitive: false,
  );

  static DateTime _parseIso8601Utc(String raw) {
    if (!_isoTimezonePattern.hasMatch(raw)) {
      throw ArgumentError.value(
        raw,
        'updatedAt',
        'Expected an ISO-8601 timestamp with an explicit timezone (Z or ±HH:MM).',
      );
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw ArgumentError.value(
        raw,
        'updatedAt',
        'Expected a valid ISO-8601 timestamp.',
      );
    }
    return parsed.toUtc();
  }

  /// Whether a credential is configured for [provider].
  bool get isConfigured => source != .unconfigured;

  /// Serializes this non-secret status DTO to JSON.
  Map<String, Object?> toJson() => {
    'provider': provider.name,
    'source': source.name,
    'keyHint': ?keyHint,
    'updatedAt': ?updatedAt?.toUtc().toIso8601String(),
  };

  /// Returns a copy of this status with the given fields updated.
  IntegrationKeyStatus copyWith({
    IntegrationProvider? provider,
    KeySource? source,
    String? Function()? keyHint,
    DateTime? Function()? updatedAt,
  }) => IntegrationKeyStatus(
    provider: provider ?? this.provider,
    source: source ?? this.source,
    keyHint: keyHint != null ? keyHint() : this.keyHint,
    updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntegrationKeyStatus &&
          other.provider == provider &&
          other.source == source &&
          other.keyHint == keyHint &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(provider, source, keyHint, updatedAt);

  @override
  String toString() =>
      'IntegrationKeyStatus(provider: $provider, source: $source, '
      'hasKeyHint: ${keyHint != null}, updatedAt: $updatedAt)';
}
