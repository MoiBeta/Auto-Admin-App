import 'package:flutter/material.dart';

// Colores tomados del ícono de la app.
const Color _navy = Color(0xFF011334);
const Color _deepBlue = Color(0xFF082858);
const Color _spark = Color(0xFFFCB400);
const Color _ember = Color(0xFFF06C00);

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: _deepBlue,
  brightness: Brightness.light,
).copyWith(
  primary: _deepBlue,
  onPrimary: Colors.white,
  primaryContainer: _deepBlue,
  onPrimaryContainer: _spark,
  secondary: const Color(0xFF7A5200),
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFFFFE19A),
  onSecondaryContainer: const Color(0xFF2A1B00),
  tertiary: const Color(0xFFA34500),
  onTertiary: Colors.white,
  tertiaryContainer: const Color(0xFFFFDCC7),
  onTertiaryContainer: const Color(0xFF331200),
  surface: const Color(0xFFF7F8FC),
  onSurface: const Color(0xFF0F1A2E),
  onSurfaceVariant: const Color(0xFF445068),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: const Color(0xFFF1F3F9),
  surfaceContainer: const Color(0xFFEBEEF6),
  surfaceContainerHigh: const Color(0xFFE5E9F2),
  surfaceContainerHighest: const Color(0xFFDFE4EE),
  outline: const Color(0xFF6C7890),
  outlineVariant: const Color(0xFFC3CBDB),
);

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: _deepBlue,
  brightness: Brightness.dark,
).copyWith(
  primary: _spark,
  onPrimary: const Color(0xFF2A1B00),
  primaryContainer: _spark,
  onPrimaryContainer: const Color(0xFF2A1B00),
  secondary: const Color(0xFFFFCF66),
  onSecondary: const Color(0xFF2A1B00),
  secondaryContainer: const Color(0xFF5C4100),
  onSecondaryContainer: const Color(0xFFFFE19A),
  tertiary: const Color(0xFFFF9A52),
  onTertiary: const Color(0xFF331200),
  tertiaryContainer: _ember,
  onTertiaryContainer: const Color(0xFF240C00),
  surface: _navy,
  onSurface: const Color(0xFFE6EAF5),
  onSurfaceVariant: const Color(0xFFB4BED4),
  surfaceContainerLowest: const Color(0xFF000D26),
  surfaceContainerLow: const Color(0xFF07193C),
  surfaceContainer: const Color(0xFF0C2147),
  surfaceContainerHigh: const Color(0xFF132A54),
  surfaceContainerHighest: const Color(0xFF1B3361),
  outline: const Color(0xFF7E8BA8),
  outlineVariant: const Color(0xFF34466B),
);
