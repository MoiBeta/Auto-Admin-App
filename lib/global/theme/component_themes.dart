import 'package:flutter/material.dart';

AppBarTheme appBarTheme(ColorScheme colorScheme) => AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 3,
      centerTitle: true,
    );

CardThemeData cardTheme(ColorScheme colorScheme) => CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surfaceContainerLow,
    );

FloatingActionButtonThemeData fabTheme(ColorScheme colorScheme) =>
    FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );

NavigationDrawerThemeData navigationDrawerTheme(ColorScheme colorScheme) =>
    NavigationDrawerThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 1,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
    );

InputDecorationTheme inputDecorationTheme(ColorScheme colorScheme) =>
    InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: UnderlineInputBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      constraints: const BoxConstraints(minHeight: 56),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

FilledButtonThemeData filledButtonTheme() => FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );

OutlinedButtonThemeData outlinedButtonTheme() => OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );

TextButtonThemeData textButtonTheme() => TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
