import 'package:flutter/material.dart';

/// アプリ共通の三色パレット（白/黒/濃い青）によるMaterial 3 テーマ
class AppTheme {
  static const Color primaryBlue = Color(0xFF0B5FFF); // 濃い青
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData lightTheme() {
    const seed = primaryBlue;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: primaryBlue,
      onPrimary: white,
      surface: white,
      onSurface: black,
      background: white,
      onBackground: black,
      secondary: primaryBlue,
      onSecondary: white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        centerTitle: false,
      ),
      checkboxTheme: const CheckboxThemeData(
        shape: StadiumBorder(),
        side: BorderSide(color: black, width: 1.6),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: black,
        textColor: black,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(primaryBlue),
          foregroundColor: MaterialStatePropertyAll(white),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          padding: MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x14000000), // 薄い黒
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        surfaceTintColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x1A000000)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
