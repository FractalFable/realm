import 'package:material_ui/material_ui.dart';
import 'package:realm_core/realm_core.dart';

/// Builds a Material [ThemeData] seeded from the operator's [VenueBranding].
ThemeData buildRealmTheme(
  VenueBranding branding, {
  Brightness brightness = .light,
}) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(branding.primaryColorArgb),
    brightness: brightness,
  ),
);
