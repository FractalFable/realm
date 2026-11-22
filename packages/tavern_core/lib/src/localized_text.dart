import 'package:meta/meta.dart';

/// Multi-language text map keyed by locale code (e.g. `en`, `sl`), with `en`
/// fallback.
@immutable
class LocalizedText._(
  /// Immutable map of locale tag to trimmed text.
  final Map<String, String> translations,
) {
  /// Validates and wraps [translations], requiring at least one non-empty entry
  /// and valid non-empty locale keys.
  factory LocalizedText(Map<String, String> translations) {
    if (translations.isEmpty) {
      throw ArgumentError.value(
        translations,
        'translations',
        'At least one localized string is required.',
      );
    }

    final normalized = <String, String>{};
    for (final MapEntry(:key, :value) in translations.entries) {
      final locale = key.trim();
      if (!_localePattern.hasMatch(locale)) {
        throw ArgumentError.value(
          key,
          'translations',
          'Locale keys must be valid language tags (e.g. en, sl).',
        );
      }
      final text = value.trim();
      if (text.isEmpty) {
        throw ArgumentError.value(
          value,
          'translations[$locale]',
          'Localized text must not be empty or whitespace.',
        );
      }
      normalized[locale] = text;
    }

    return LocalizedText._(Map.unmodifiable(normalized));
  }

  /// Decodes and validates a [LocalizedText] from a JSON object.
  factory LocalizedText.fromJson(Map<String, Object?> json) {
    final parsed = <String, String>{};
    for (final MapEntry(:key, :value) in json.entries) {
      if (value is! String) {
        throw ArgumentError.value(
          value,
          key,
          'Expected a string translation for locale $key.',
        );
      }
      parsed[key] = value;
    }
    return LocalizedText(parsed);
  }

  static final RegExp _localePattern = RegExp(r'^[a-z]{2,3}(?:-[A-Z]{2})?$');

  /// Resolves text for [locale], falling back to `en` and then the first
  /// available translation.
  String resolve(String locale) {
    final trimmed = locale.trim();
    if (translations[trimmed] case final exact?) {
      return exact;
    }
    final languageOnly = trimmed.split('-').first;
    if (translations[languageOnly] case final base?) {
      return base;
    }
    if (translations['en'] case final english?) {
      return english;
    }
    return translations.values.first;
  }

  /// Serializes this localized text map to JSON.
  Map<String, Object?> toJson() => Map<String, Object?>.of(translations);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! LocalizedText ||
        other.translations.length != translations.length) {
      return false;
    }
    for (final MapEntry(:key, :value) in translations.entries) {
      if (other.translations[key] != value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    translations.entries.map((e) => Object.hash(e.key, e.value)),
  );

  @override
  String toString() => 'LocalizedText($translations)';
}
