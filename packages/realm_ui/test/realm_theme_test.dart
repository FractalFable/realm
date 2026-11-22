import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:realm_core/realm_core.dart';
import 'package:realm_ui/realm_ui.dart';

void main() {
  final branding = VenueBranding(
    name: 'The Crown',
    primaryColorArgb: 0xFF6B2D5C,
  );

  test('buildRealmTheme creates a seeded light theme by default', () {
    final theme = buildRealmTheme(branding);
    final expectedScheme = ColorScheme.fromSeed(
      seedColor: Color(branding.primaryColorArgb),
    );

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, expectedScheme.primary);
  });

  test('buildRealmTheme supports dark brightness via dot shorthand', () {
    final theme = buildRealmTheme(branding, brightness: .dark);
    final expectedScheme = ColorScheme.fromSeed(
      seedColor: Color(branding.primaryColorArgb),
      brightness: Brightness.dark,
    );

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, expectedScheme.primary);
  });

  test('distinct primaryColorArgb values produce distinct theme primaries', () {
    final altBranding = branding.copyWith(primaryColorArgb: 0xFF1B5E20);

    final firstTheme = buildRealmTheme(branding);
    final secondTheme = buildRealmTheme(altBranding);

    expect(
      firstTheme.colorScheme.primary,
      isNot(equals(secondTheme.colorScheme.primary)),
    );
  });
}
