import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTheme {
  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: palette.bg,
      fontFamily: 'Noto Sans KR',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.accent,
        onPrimary: palette.accentInk,
        secondary: palette.accent,
        onSecondary: palette.accentInk,
        error: palette.warn,
        onError: Colors.white,
        surface: palette.surface,
        onSurface: palette.text,
      ),
      extensions: [palette],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 2),
        ),
        hintStyle: TextStyle(color: palette.textFaint),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.accent,
        selectionColor: palette.accentSoft,
        selectionHandleColor: palette.accent,
      ),
    );
  }
}
