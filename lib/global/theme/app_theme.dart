import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'typography.dart';
import 'component_themes.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(lightColorScheme);
  static ThemeData get darkTheme => _buildTheme(darkColorScheme);

  static ThemeData _buildTheme(ColorScheme colorScheme) => ThemeData(
        colorScheme: colorScheme,
        brightness: colorScheme.brightness,
        useMaterial3: true,
        textTheme: appTextTheme,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: appBarTheme(colorScheme),
        cardTheme: cardTheme(colorScheme),
        floatingActionButtonTheme: fabTheme(colorScheme),
        navigationDrawerTheme: navigationDrawerTheme(colorScheme),
        inputDecorationTheme: inputDecorationTheme(colorScheme),
        filledButtonTheme: filledButtonTheme(),
        outlinedButtonTheme: outlinedButtonTheme(),
        textButtonTheme: textButtonTheme(),
      );
}
