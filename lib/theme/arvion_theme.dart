import 'package:flutter/material.dart';

/// Brand tokens for the app. The values mirror the design tokens used by the
/// case-study site; the app does not load a font file in this sample because the
/// production app ships Poppins and Inter as bundled assets.
class ArvionColors {
  static const bg = Color(0xFF0B0F1A);
  static const surface = Color(0xFF121826);
  static const surface2 = Color(0xFF171F31);
  static const gold = Color(0xFFF5C26B);
  static const blue = Color(0xFF3A7BFF);
  static const green = Color(0xFF34D399);
  static const red = Color(0xFFF87171);
  static const text = Color(0xFFFFFFFF);
  static const text2 = Color(0xFFCFD6E4);
  static const muted = Color(0xFF8D98AB);
  static const line = Color(0x14FFFFFF);
}

class ArvionTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: ArvionColors.gold,
      onPrimary: Color(0xFF1A1405),
      secondary: ArvionColors.blue,
      onSecondary: Colors.white,
      surface: ArvionColors.surface,
      onSurface: ArvionColors.text,
      error: ArvionColors.red,
      onError: Colors.white,
    );

    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: ArvionColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: ArvionColors.bg,
        foregroundColor: ArvionColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: ArvionColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ArvionColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ArvionColors.gold,
          foregroundColor: const Color(0xFF1A1405),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ArvionColors.text2,
          side: const BorderSide(color: ArvionColors.line),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: ArvionColors.text2,
        displayColor: ArvionColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArvionColors.surface2,
        hintStyle: const TextStyle(color: ArvionColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ArvionColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ArvionColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ArvionColors.gold),
        ),
      ),
      dividerColor: ArvionColors.line,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: ArvionColors.surface,
        indicatorColor: Color(0x1FF5C26B),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
