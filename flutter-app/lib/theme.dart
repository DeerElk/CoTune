import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class CotuneModalTheme extends ThemeExtension<CotuneModalTheme> {
  final Color background;
  final Color handle;
  final Color barrier;
  final Color shadow;
  final Color inputFill;
  final Color inputBorder;
  final Color hint;
  final Color cancelButtonBg;
  final Color confirmText;

  const CotuneModalTheme({
    required this.background,
    required this.handle,
    required this.barrier,
    required this.shadow,
    required this.inputFill,
    required this.inputBorder,
    required this.hint,
    required this.cancelButtonBg,
    required this.confirmText,
  });

  @override
  CotuneModalTheme copyWith({
    Color? background,
    Color? handle,
    Color? barrier,
    Color? shadow,
    Color? inputFill,
    Color? inputBorder,
    Color? hint,
    Color? cancelButtonBg,
    Color? confirmText,
  }) {
    return CotuneModalTheme(
      background: background ?? this.background,
      handle: handle ?? this.handle,
      barrier: barrier ?? this.barrier,
      shadow: shadow ?? this.shadow,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      hint: hint ?? this.hint,
      cancelButtonBg: cancelButtonBg ?? this.cancelButtonBg,
      confirmText: confirmText ?? this.confirmText,
    );
  }

  @override
  CotuneModalTheme lerp(ThemeExtension<CotuneModalTheme>? other, double t) {
    if (other is! CotuneModalTheme) return this;
    return CotuneModalTheme(
      background: Color.lerp(background, other.background, t)!,
      handle: Color.lerp(handle, other.handle, t)!,
      barrier: Color.lerp(barrier, other.barrier, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      cancelButtonBg: Color.lerp(cancelButtonBg, other.cancelButtonBg, t)!,
      confirmText: Color.lerp(confirmText, other.confirmText, t)!,
    );
  }
}

// ------------------------------------------------------------

class CotuneTheme {
  static const Color highlight = Color(0xFF28D5D1);
  static const Color headerTextColor = Colors.black;

  // ---------------- LIGHT ----------------

  static ThemeData lightTheme() {
    final base = ThemeData.light();

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: highlight,
      brightness: Brightness.light,
      background: Colors.white,
      surface: const Color(0xFFF6F7FB),
      onPrimary: headerTextColor,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: textTheme,

      extensions: [
        const CotuneModalTheme(
          background: Color(0xFFF6F7FB),
          handle: Color(0xFF000000),
          barrier: Colors.black26,
          shadow: Colors.black12,
          inputFill: Color(0xFFE9EBF1),
          inputBorder: Colors.black12,
          hint: Color(0xFF6B6B6B),
          cancelButtonBg: Color(0xFFE0E0E0),
          confirmText: Colors.black,
        ),
      ],

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: highlight,
          foregroundColor: headerTextColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ---------------- DARK ----------------

  static ThemeData darkTheme() {
    final base = ThemeData.dark();

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme);

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: const Color(0xFFB3B3B3),
      onSecondary: Colors.white,
      surface: const Color(0xFF121212),
      onSurface: Colors.white,
      background: Colors.black,
      onBackground: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: textTheme,

      extensions: [
        const CotuneModalTheme(
          background: Color(0xFF121212),
          handle: Colors.white54,
          barrier: Colors.black54,
          shadow: Colors.black87,
          inputFill: Color(0xFF1D1D1D),
          inputBorder: Colors.white12,
          hint: Colors.white54,
          cancelButtonBg: Color(0xFF2A2A2A),
          confirmText: Colors.black,
        ),
      ],

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: highlight,
          foregroundColor: headerTextColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
