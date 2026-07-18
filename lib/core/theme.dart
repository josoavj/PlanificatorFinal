import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accentBlue = Color(0xFF42A5F5);

  // Couleurs fonctionnelles
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFE53935);
  static const Color infoBlue = Color(0xFF2196F3);

  // Couleurs neutres
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFFBDBDBD);
  static const Color darkGrey = Color(0xFF424242);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Ombres partagées (Optimisation performance)
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Retourne une décoration de carte adaptée au thème (Optimisé performance)
  static BoxDecoration cardDecoration(BuildContext context, {double radius = 12, bool showShadow = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkCardBg : Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? glassBorder.withValues(alpha: 0.1) : mediumGrey.withValues(alpha: 0.2),
      ),
      boxShadow: (showShadow && !isDark) ? softShadow : null,
    );
  }

  // Thème de texte centralisé
  static final _baseTextTheme = GoogleFonts.poppinsTextTheme();

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Colors.white,
    textTheme: _baseTextTheme.apply(
      bodyColor: darkGrey,
      displayColor: darkGrey,
    ),
    fontFamily: _baseTextTheme.bodyLarge?.fontFamily,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: mediumGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: mediumGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      labelStyle: const TextStyle(color: darkGrey),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Cards
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
    ),

    // Dialog
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 4,
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      elevation: 4,
    ),

    // Chip
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: lightGrey,
      selectedColor: primaryBlue,
      labelStyle: const TextStyle(color: darkGrey),
    ),

    // Color scheme
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: accentBlue,
      error: errorRed,
    ),
  );

  // Palettes couleur pour le thème sombre GLASSMORPHISM iOS16+
  static const Color darkBg = Color(0xFF0F111D);
  static const Color darkBgSecondary = Color(0xFF1A1F3A);
  static const Color darkBgTertiary = Color(0xFF242B48);
  static const Color darkCardBg = Color(0xFF1F2744);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFC5CEE0);
  static const Color darkTextTertiary = Color(0xFF888FA3);

  // Couleurs vibrantes pour statuts en mode sombre
  static const Color darkSuccess = Color(0xFF00C853);
  static const Color darkWarning = Color(0xFFFFAB00);
  static const Color darkError = Color(0xFFFF1744);

  // Glassmorphism colors - teintes bleu/violet subtiles
  static const Color glassLight = Color(0xFF2D3561);
  static const Color glassBorder = Color(0x4DFFFFFF); // Blanc transparent

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: accentBlue,
    scaffoldBackgroundColor: darkBg,
    fontFamily: _baseTextTheme.bodyLarge?.fontFamily,

    // AppBar avec glassmorphism
    appBarTheme: AppBarTheme(
      backgroundColor: darkBgSecondary.withValues(alpha: 0.8),
      foregroundColor: darkTextPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),

    // Input decoration avec glassmorphism
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassLight.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      labelStyle: const TextStyle(color: darkTextSecondary),
      hintStyle: const TextStyle(color: darkTextTertiary),
      iconColor: darkTextSecondary,
      prefixIconColor: darkTextSecondary,
      suffixIconColor: darkTextSecondary,
    ),

    // Buttons avec glassmorphism
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue.withValues(alpha: 0.9),
        foregroundColor: darkTextPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentBlue,
        side: BorderSide(color: glassBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Cards avec glassmorphism
    cardTheme: CardThemeData(
      elevation: 0,
      color: glassLight.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: glassBorder),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      surfaceTintColor: Colors.transparent,
    ),

    // Dialog avec glassmorphism
    dialogTheme: DialogThemeData(
      backgroundColor: glassLight.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: glassBorder),
      ),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        color: darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
    ),

    // BottomSheet avec glassmorphism
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: glassLight.withValues(alpha: 0.8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    // Chip avec glassmorphism
    chipTheme: ChipThemeData(
      backgroundColor: glassLight.withValues(alpha: 0.6),
      selectedColor: accentBlue.withValues(alpha: 0.8),
      labelStyle: const TextStyle(color: darkTextPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: true,
      checkmarkColor: darkBg,
    ),

    // Typography - Centralisée
    textTheme: _baseTextTheme.apply(
      bodyColor: darkTextPrimary,
      displayColor: darkTextPrimary,
    ),

    // Color scheme avec glassmorphism
    colorScheme: ColorScheme.dark(
      primary: accentBlue,
      secondary: accentBlue,
      error: errorRed,
      surface: glassLight.withValues(alpha: 0.5),
      surfaceContainer: glassLight.withValues(alpha: 0.3),
    ),
  );

  // Styles personnalisés
  static BoxDecoration get gradientBoxDecoration {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.circular(12),
    );
  }

  static BoxDecoration getGradientBoxDecoration(List<Color> colors) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    );
  }
}
