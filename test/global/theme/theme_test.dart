import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_admin_app/global/theme/color_schemes.dart';
import 'package:auto_admin_app/global/theme/component_themes.dart';

void main() {
  group('Color Schemes', () {
    test('lightColorScheme has Brightness.light', () {
      expect(lightColorScheme.brightness, Brightness.light);
    });

    test('darkColorScheme has Brightness.dark', () {
      expect(darkColorScheme.brightness, Brightness.dark);
    });

    test('both schemes use the colors of the app icon', () {
      expect(lightColorScheme.primary, const Color(0xFF082858));
      expect(darkColorScheme.primary, const Color(0xFFFCB400));
      expect(darkColorScheme.surface, const Color(0xFF011334));
    });
  });

  group('AppBar Theme', () {
    test('elevation is 0', () {
      final theme = appBarTheme(lightColorScheme);
      expect(theme.elevation, 0);
    });

    test('scrolledUnderElevation is 3', () {
      final theme = appBarTheme(lightColorScheme);
      expect(theme.scrolledUnderElevation, 3);
    });

    test('centerTitle is true', () {
      final theme = appBarTheme(lightColorScheme);
      expect(theme.centerTitle, true);
    });

    test('backgroundColor is colorScheme.surface', () {
      final theme = appBarTheme(lightColorScheme);
      expect(theme.backgroundColor, lightColorScheme.surface);
    });

    test('foregroundColor is colorScheme.onSurface', () {
      final theme = appBarTheme(lightColorScheme);
      expect(theme.foregroundColor, lightColorScheme.onSurface);
    });
  });

  group('Card Theme', () {
    test('elevation is 1', () {
      final theme = cardTheme(lightColorScheme);
      expect(theme.elevation, 1);
    });

    test('shape has borderRadius of 12', () {
      final theme = cardTheme(lightColorScheme);
      final shape = theme.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;
      expect(borderRadius, BorderRadius.circular(12));
    });

    test('color is surfaceContainerLow', () {
      final theme = cardTheme(lightColorScheme);
      expect(theme.color, lightColorScheme.surfaceContainerLow);
    });
  });

  group('FAB Theme', () {
    test('elevation is 3', () {
      final theme = fabTheme(lightColorScheme);
      expect(theme.elevation, 3);
    });

    test('shape has borderRadius of 16', () {
      final theme = fabTheme(lightColorScheme);
      final shape = theme.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;
      expect(borderRadius, BorderRadius.circular(16));
    });

    test('backgroundColor is primaryContainer', () {
      final theme = fabTheme(lightColorScheme);
      expect(theme.backgroundColor, lightColorScheme.primaryContainer);
    });

    test('foregroundColor is onPrimaryContainer', () {
      final theme = fabTheme(lightColorScheme);
      expect(theme.foregroundColor, lightColorScheme.onPrimaryContainer);
    });
  });

  group('Navigation Drawer Theme', () {
    test('elevation is 1', () {
      final theme = navigationDrawerTheme(lightColorScheme);
      expect(theme.elevation, 1);
    });

    test('backgroundColor is surface', () {
      final theme = navigationDrawerTheme(lightColorScheme);
      expect(theme.backgroundColor, lightColorScheme.surface);
    });

    test('indicatorColor is secondaryContainer', () {
      final theme = navigationDrawerTheme(lightColorScheme);
      expect(theme.indicatorColor, lightColorScheme.secondaryContainer);
    });
  });

  group('Filled Button Theme', () {
    test('minimumSize height is 48', () {
      final theme = filledButtonTheme();
      final resolvedSize = theme.style!.minimumSize!.resolve({});
      expect(resolvedSize!.height, 48);
    });

    test('minimumSize width is 64', () {
      final theme = filledButtonTheme();
      final resolvedSize = theme.style!.minimumSize!.resolve({});
      expect(resolvedSize!.width, 64);
    });

    test('shape is StadiumBorder', () {
      final theme = filledButtonTheme();
      final resolvedShape = theme.style!.shape!.resolve({});
      expect(resolvedShape, isA<StadiumBorder>());
    });
  });

  group('Outlined Button Theme', () {
    test('minimumSize height is 48', () {
      final theme = outlinedButtonTheme();
      final resolvedSize = theme.style!.minimumSize!.resolve({});
      expect(resolvedSize!.height, 48);
    });

    test('shape is StadiumBorder', () {
      final theme = outlinedButtonTheme();
      final resolvedShape = theme.style!.shape!.resolve({});
      expect(resolvedShape, isA<StadiumBorder>());
    });
  });

  group('Text Button Theme', () {
    test('minimumSize height is 48', () {
      final theme = textButtonTheme();
      final resolvedSize = theme.style!.minimumSize!.resolve({});
      expect(resolvedSize!.height, 48);
    });

    test('shape is StadiumBorder', () {
      final theme = textButtonTheme();
      final resolvedShape = theme.style!.shape!.resolve({});
      expect(resolvedShape, isA<StadiumBorder>());
    });
  });
}
