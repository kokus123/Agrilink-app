import 'package:flutter/material.dart';

class AppColors {
  // Couleurs directement extraites du logo AgriLink
  static const Color primary = Color(0xFF0B4D3C); // Vert sapin profond (Lettre A)
  static const Color primaryDark = Color(0xFF063327);
  static const Color primaryLight = Color(0xFF166853);

  static const Color accent = Color(0xFF5CB82F); // Vert feuille vif (Feuille et Lettre L)
  static const Color accentLight = Color(0xFF7ED957);
  static const Color accentDark = Color(0xFF459420);

  // Dégradés signature
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0B4D3C), Color(0xFF267D45), Color(0xFF5CB82F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF0B4D3C), Color(0xFF388E3C)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF083C2F), Color(0xFF0E5C49)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Surfaces & Fonds
  static const Color background = Color(0xFFF6FAF7);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFEEF5F1);

  // Textes
  static const Color textPrimary = Color(0xFF102820);
  static const Color textSecondary = Color(0xFF536E65);
  static const Color textMuted = Color(0xFF8BA39A);

  // Éléments de formulaire
  static const Color inputBg = Color(0xFFF7FAF8);
  static const Color inputBorder = Color(0xFFDCE7E1);
  static const Color inputFocusBorder = Color(0xFF0B4D3C);

  // Statuts
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningBg = Color(0xFFFFF3E0);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: null, // utilise la police système moderne
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
      ),
    );
  }
}
