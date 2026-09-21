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

  // Alias sémantique générique (bordures hors formulaires : séparateurs, cartes)
  static const Color border = inputBorder;

  // Statuts
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningBg = Color(0xFFFFF3E0);

  // ---------------------------------------------------------------------
  // Tons doux "Soft Pastel Agricultural UI" (refonte UI/UX)
  // Dérivés du vert de la marque, pas des couleurs génériques du brief.
  // ---------------------------------------------------------------------
  static const Color sage = Color(0xFFA8C8B0); // vert sauge doux (texte/icônes secondaires)
  static const Color mint = Color(0xFFDFF1E5); // vert menthe très léger (backgrounds de section)
  static const Color cream = Color(0xFFFAF8F2); // crème (alternative douce à `background`)
  static const Color lightBeige = Color(0xFFF3EFE5); // beige très clair (variation de fond)

  // Fonds pastel dérivés de la marque, pour capsules/badges/icônes actives
  static const Color accentSurface = Color(0xFFEAF5ED); // pastel dérivé de `accent`
  static const Color primarySurface = Color(0xFFE3EEE8); // pastel dérivé de `primary`

  // Accent secondaire occasionnel, réservé aux fonctionnalités IA
  // (prédiction de prix, simulation de revenus, assistant) — brief section 22.
  static const Color aiAccent = Color(0xFFE7B93A);
  static const Color aiAccentBg = Color(0xFFFFF6DE);

  // Badge Premium (abonnement agriculteur) — distinct de l'accent IA
  static const Color premium = Color(0xFFC9971C);
  static const Color premiumBg = Color(0xFFFBF0D9);
}

/// Échelle d'espacement unique de l'application (brief section 12).
/// Toujours utiliser ces constantes plutôt que des valeurs en dur.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

/// Système de rayons unique (brief section 6).
class AppRadius {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 20;
  static const double extraLarge = 26;

  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get extraLargeRadius => BorderRadius.circular(extraLarge);

  /// Pilule / capsule (badges, chips, éléments de nav actifs)
  static BorderRadius get pill => BorderRadius.circular(999);
}

/// Ombres volontairement presque imperceptibles (brief section 27).
class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.22),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  /// Lueur douce sous un bouton, dans la couleur du bouton lui-même
  /// (utilisé par FlatActionButton, dont la couleur varie selon l'écran).
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Hiérarchie typographique (brief section 11).
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  /// Label au-dessus d'un champ de saisie (ModernTextField, AgrilinkTextField).
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );
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
          borderRadius: AppRadius.largeRadius,
          side: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
      ),

      // -----------------------------------------------------------------
      // Thèmes de composants pour la refonte
      // -----------------------------------------------------------------
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.displayLarge,
        titleLarge: AppTextStyles.sectionTitle,
        titleMedium: AppTextStyles.cardTitle,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodySecondary,
        labelSmall: AppTextStyles.caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
          textStyle: AppTextStyles.buttonLabel,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.inputBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
          textStyle: AppTextStyles.buttonLabel.copyWith(color: AppColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        labelStyle: AppTextStyles.bodySecondary,
        hintStyle: AppTextStyles.bodySecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
        side: BorderSide.none,
      ),
    );
  }
}