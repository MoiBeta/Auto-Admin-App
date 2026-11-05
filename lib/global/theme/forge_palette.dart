import 'package:flutter/material.dart';

/// Colors of the forge animation. Same in light and dark themes: hot and
/// tempered metal do not depend on the theme.
abstract final class ForgePalette {
  static const Color hot = Color(0xFFF06C00);
  static const Color onHot = Color(0xFF240C00);
  static const Color steel = Color(0xFF39424E);
  static const Color onSteel = Color(0xFFE6EAF0);
  static const Color steelAccent = Color(0xFFFCB400);

  static const Color flameFallback = Color(0xFFFF8A1F);
  static const Color flameFallbackCore = Color(0xFFFFE9A8);

  static const Color emberHot = Color(0xFFFFD45C);
  static const Color emberCold = Color(0xFFD8360B);
}

/// How a task card looks in each moment of the animation.
enum ForgeLook {
  pending,
  hot,
  forged;

  /// The [base] theme with this look's colors, for the card's subtree.
  ThemeData applyTo(ThemeData base) {
    final (foreground, accent) = switch (this) {
      ForgeLook.pending => (null, null),
      ForgeLook.hot => (ForgePalette.onHot, ForgePalette.onHot),
      ForgeLook.forged => (ForgePalette.onSteel, ForgePalette.steelAccent),
    };
    if (foreground == null) return base;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        onSurface: foreground,
        onSurfaceVariant: foreground,
        surfaceContainerHighest: foreground.withValues(alpha: 0.25),
      ),
      iconTheme: base.iconTheme.copyWith(color: foreground),
      textTheme:
          base.textTheme.apply(bodyColor: foreground, displayColor: foreground),
    );
  }

  /// Background of the card, or null to use the one of the theme.
  Color? get cardColor => switch (this) {
        ForgeLook.pending => null,
        ForgeLook.hot => ForgePalette.hot,
        ForgeLook.forged => ForgePalette.steel,
      };
}
