import 'package:auto_admin_app/global/theme/color_schemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  for (final (name, scheme) in [
    ('light', lightColorScheme),
    ('dark', darkColorScheme),
  ]) {
    test('$name scheme keeps text readable (WCAG AA)', () {
      final pairs = {
        'primary': (scheme.onPrimary, scheme.primary),
        'primaryContainer': (scheme.onPrimaryContainer, scheme.primaryContainer),
        'secondary': (scheme.onSecondary, scheme.secondary),
        'secondaryContainer': (
          scheme.onSecondaryContainer,
          scheme.secondaryContainer
        ),
        'tertiary': (scheme.onTertiary, scheme.tertiary),
        'tertiaryContainer': (
          scheme.onTertiaryContainer,
          scheme.tertiaryContainer
        ),
        'surface': (scheme.onSurface, scheme.surface),
        'surfaceVariant on highest': (
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest
        ),
        'primary on surface': (scheme.primary, scheme.surface),
      };
      pairs.forEach((label, pair) {
        expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5),
            reason: label);
      });
    });
  }
}
