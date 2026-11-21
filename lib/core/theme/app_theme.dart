import 'package:flutter/material.dart';

/// Tema visual moderno en MODO CLARO (WCAG 2.2 AA).
/// Fondo blanco ultra limpio (#F8FAFC / #FFFFFF), tarjetas blancas con borde sutil (#E2E8F0),
/// acento Índigo profundo de alto contraste (#4338CA) con ratio > 7:1 contra fondo blanco,
/// y tipografías en Dark Slate (#0F172A) y Slate (#475569) con ratio >= 4.5:1.
class AppTheme {
  // Paleta Modo Claro Moderno de Alto Contraste (WCAG 2.2 AA)
  static const Color background = Color(0xFFF8FAFC); // Slate 50 ultra limpio
  static const Color surface = Color(0xFFFFFFFF); // Blanco puro
  static const Color surfaceLight = Color(0xFFF1F5F9); // Slate 100
  static const Color primary = Color(0xFF4338CA); // Deep Indigo (> 7:1 de contraste)
  static const Color primaryLight = Color(0xFF4F46E5); // Indigo 600 (> 4.5:1 contra blanco)
  static const Color primaryHover = Color(0xFF3730A3); // Deep Indigo hover (> 9:1)
  static const Color secondary = Color(0xFF0F766E); // Teal 700 (> 5.3:1 contra blanco)
  static const Color success = Color(0xFF047857); // Emerald 700 (> 5.1:1 contra blanco)
  static const Color warning = Color(0xFFB45309); // Amber 700 (> 4.9:1 contra blanco, ratio WCAG AA)
  static const Color error = Color(0xFFB91C1C); // Red 700 (> 6.8:1 contra blanco)

  // Tipografía de alto contraste WCAG 2.2 AA
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate (ratio > 12:1)
  static const Color textSecondary = Color(0xFF334155); // Slate 700 (ratio > 7:1)
  static const Color textMuted = Color(0xFF475569); // Slate 600 (ratio > 4.5:1 en cualquier superficie clara)

  // Bordes sutiles y delimitadores de componentes interactivos (WCAG 2.2 AA 1.4.11 >= 3:1)
  static const Color borderSubtle = Color(0xFFCBD5E1); // Slate 300
  static const Color borderMedium = Color(0xFF94A3B8); // Slate 400 (ratio >= 3:1 contra fondo blanco)

  static ThemeData lightTheme() => modernLightTheme();

  static ThemeData darkTheme() => modernLightTheme();

  static ThemeData modernLightTheme() {
    final colorScheme = ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          disabledForegroundColor: const Color(0xFF475569),
          elevation: 1,
          minimumSize: const Size(double.infinity, 54),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: const BorderSide(color: borderMedium, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textMuted, fontSize: 15),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 12,
        ),
      ),
    );
  }
}
