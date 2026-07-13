import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cupertino_theme.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color bg = Color(0xFF0D0D1A);
  static const Color card = Color(0xFF14142A);
  static const Color cardElevated = Color(0xFF1C1C35);
  static const Color cardHigher = Color(0xFF242445);
  static const Color border = Color(0xFF2A2A45);
  static const Color borderLight = Color(0xFF353555);

  // Text
  static const Color text = Color(0xFFECECFC);
  static const Color textSecondary = Color(0xFFB4B4D0);
  static const Color sub = Color(0xFF55557A);
  static const Color subM = Color(0xFF7070A0);

  // Brand palette
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFC084FC);
  static const Color purpleGlow = Color(0xFF6D28D9);
  static const Color green = Color(0xFF22C55E);
  static const Color greenLight = Color(0xFF4ADE80);
  static const Color neon = Color(0xFF00F5B0);
  static const Color neonGlow = Color(0xFF00CC8A);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFF60A5FA);

  // Elevation shadow colors
  static const Color shadowLevel1 = Color(0x0A000000);
  static const Color shadowLevel2 = Color(0x14000000);
  static const Color shadowLevel3 = Color(0x1E000000);

  static List<BoxShadow> glow(Color color, {double radius = 8, double opacity = 0.3}) {
    return [
      BoxShadow(color: color.withAlpha((opacity * 255).round()), blurRadius: radius, spreadRadius: 0),
      BoxShadow(color: color.withAlpha(((opacity * 0.6) * 255).round()), blurRadius: radius * 2, spreadRadius: -radius * 0.3),
    ];
  }
}

class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double pageH = 14;
}

class AppElevation {
  AppElevation._();
  static List<BoxShadow> level0 = const [];
  static List<BoxShadow> level1 = [
    BoxShadow(color: AppColors.shadowLevel1, blurRadius: 2, offset: Offset(0, 1)),
  ];
  static List<BoxShadow> level2 = [
    BoxShadow(color: AppColors.shadowLevel1, blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: AppColors.shadowLevel2, blurRadius: 8, offset: Offset(0, 4)),
  ];
  static List<BoxShadow> level3 = [
    BoxShadow(color: AppColors.shadowLevel1, blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(color: AppColors.shadowLevel2, blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: AppColors.shadowLevel3, blurRadius: 24, offset: Offset(0, 12)),
  ];
}

TextStyle _bc(double size, FontWeight w, {Color? color, double? ls}) {
  return GoogleFonts.barlowCondensed(fontSize: size, fontWeight: w, color: color, letterSpacing: ls);
}

TextStyle _b(double size, FontWeight w, {Color? color, double? ls}) {
  return GoogleFonts.barlow(fontSize: size, fontWeight: w, color: color, letterSpacing: ls);
}

class AppStyles {
  AppStyles._();
  static TextStyle pageTitle = _bc(21, FontWeight.w800, color: AppColors.text);
  static TextStyle sectionTitle = _bc(18, FontWeight.w700, color: AppColors.text);
  static TextStyle statValue = _bc(22, FontWeight.w800);
  static TextStyle cardTitle = _b(14, FontWeight.w700, color: AppColors.text);
  static TextStyle cardSubtitle = _b(12, FontWeight.w500, color: AppColors.sub);
  static TextStyle errorText = _b(12, FontWeight.w400, color: AppColors.subM);
  static TextStyle label = _b(10, FontWeight.w500, color: AppColors.sub);
}

/// Legacy/alternative dark neon theme. Use iOSTheme for primary iOS-native styling.
final ThemeData darkNeonTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: AppColors.purple,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFF1E1050),
    onPrimaryContainer: const Color(0xFFD8B4FE),
    secondary: AppColors.neon,
    onSecondary: const Color(0xFF003320),
    secondaryContainer: const Color(0xFF005232),
    onSecondaryContainer: const Color(0xFF88F5C8),
    tertiary: AppColors.green,
    onTertiary: const Color(0xFF052E16),
    tertiaryContainer: const Color(0xFF0A4A1E),
    onTertiaryContainer: const Color(0xFF86EFAC),
    error: AppColors.red,
    onError: Colors.white,
    errorContainer: const Color(0xFF4A0000),
    onErrorContainer: const Color(0xFFFCA5A5),
    surface: AppColors.bg,
    onSurface: AppColors.text,
    surfaceContainerLowest: AppColors.bg,
    surfaceContainerLow: AppColors.card,
    surfaceContainer: AppColors.cardElevated,
    surfaceContainerHigh: AppColors.cardHigher,
    surfaceContainerHighest: const Color(0xFF2A2A50),
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.borderLight,
    shadow: Colors.black.withAlpha(100),
  ),
  scaffoldBackgroundColor: AppColors.bg,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0.5,
    centerTitle: false,
    titleTextStyle: _b(18, FontWeight.w700, color: AppColors.text),
    iconTheme: const IconThemeData(color: AppColors.text),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF0A0A16),
    indicatorColor: AppColors.purple.withAlpha(35),
    surfaceTintColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return _b(10, FontWeight.w700, color: AppColors.purpleLight, ls: 0.3);
      }
      return _b(10, FontWeight.w500, color: AppColors.sub);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.purpleLight, size: 20);
      }
      return const IconThemeData(color: AppColors.sub, size: 20);
    }),
    height: 66,
    elevation: 0,
    overlayColor: WidgetStateProperty.all(Colors.transparent),
  ),
  cardTheme: CardThemeData(
    color: AppColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shadowColor: Colors.transparent,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.purple,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: _b(14, FontWeight.w700),
      shadowColor: AppColors.purple.withAlpha(60),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return Colors.white.withAlpha(30);
        if (states.contains(WidgetState.hovered)) return Colors.white.withAlpha(15);
        return null;
      }),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.purple,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: _b(14, FontWeight.w700),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return Colors.white.withAlpha(30);
        if (states.contains(WidgetState.hovered)) return Colors.white.withAlpha(15);
        return null;
      }),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.purpleLight,
      textStyle: _b(14, FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardElevated,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.red, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    labelStyle: _b(13, FontWeight.w500, color: AppColors.sub),
    hintStyle: _b(13, FontWeight.w400, color: AppColors.subM),
    errorStyle: _b(11, FontWeight.w500, color: AppColors.red),
    helperStyle: _b(11, FontWeight.w400, color: AppColors.subM),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.cardElevated,
    labelStyle: _b(12, FontWeight.w500, color: AppColors.text),
    side: BorderSide(color: AppColors.borderLight),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.cardHigher,
    contentTextStyle: _b(13, FontWeight.w500, color: AppColors.text),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  dividerTheme: DividerThemeData(
    color: AppColors.border.withAlpha(80),
    thickness: 0.5,
    space: 0,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.card,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.card,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  textTheme: TextTheme(
    displayLarge: _bc(32, FontWeight.w800, color: AppColors.text, ls: -0.5),
    displayMedium: _bc(28, FontWeight.w800, color: AppColors.text, ls: -0.3),
    displaySmall: _bc(24, FontWeight.w700, color: AppColors.text, ls: -0.2),
    headlineLarge: _bc(22, FontWeight.w700, color: AppColors.text, ls: -0.2),
    headlineMedium: _bc(20, FontWeight.w700, color: AppColors.text, ls: -0.1),
    headlineSmall: _bc(18, FontWeight.w600, color: AppColors.text, ls: 0),
    titleLarge: _b(18, FontWeight.w700, color: AppColors.text),
    titleMedium: _b(16, FontWeight.w600, color: AppColors.text),
    titleSmall: _b(14, FontWeight.w600, color: AppColors.textSecondary),
    bodyLarge: _b(16, FontWeight.w400, color: AppColors.text),
    bodyMedium: _b(14, FontWeight.w400, color: AppColors.text),
    bodySmall: _b(12, FontWeight.w400, color: AppColors.textSecondary),
    labelLarge: _b(14, FontWeight.w600, color: AppColors.text),
    labelMedium: _b(12, FontWeight.w500, color: AppColors.textSecondary),
    labelSmall: _b(10, FontWeight.w500, color: AppColors.sub),
  ),
);

/// Primary iOS-native theme using Cupertino-style dark palette and SF Pro fonts.
final ThemeData iOSThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: CupertinoAppColors.purple,
    onPrimary: Colors.white,
    primaryContainer: CupertinoAppColors.purple.withAlpha(40),
    onPrimaryContainer: CupertinoAppColors.purpleLight,
    secondary: CupertinoAppColors.neon,
    onSecondary: const Color(0xFF003320),
    secondaryContainer: const Color(0xFF005232),
    onSecondaryContainer: const Color(0xFF88F5C8),
    tertiary: CupertinoAppColors.green,
    onTertiary: const Color(0xFF052E16),
    error: CupertinoAppColors.red,
    onError: Colors.white,
    errorContainer: CupertinoAppColors.red.withAlpha(40),
    onErrorContainer: CupertinoAppColors.red,
    surface: CupertinoAppColors.background,
    onSurface: CupertinoAppColors.textPrimary,
    onSurfaceVariant: CupertinoAppColors.textSecondary,
    outline: CupertinoAppColors.separator,
    outlineVariant: CupertinoAppColors.separatorOpaque,
  ),
  scaffoldBackgroundColor: CupertinoAppColors.background,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0.5,
    centerTitle: false,
    titleTextStyle: sfText(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: CupertinoAppColors.textPrimary,
    ),
    iconTheme: IconThemeData(color: CupertinoAppColors.textPrimary),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: CupertinoAppColors.cardElevated,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: CupertinoAppColors.separator),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: CupertinoAppColors.separator),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: CupertinoAppColors.purple, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: CupertinoAppColors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: CupertinoAppColors.red, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    labelStyle: sfText(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: CupertinoAppColors.textSecondary,
    ),
    hintStyle: sfText(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: CupertinoAppColors.textTertiary,
    ),
    errorStyle: sfText(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: CupertinoAppColors.red,
    ),
  ),
  textTheme: TextTheme(
    displayLarge: sfText(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: 0.37,
    ),
    displayMedium: sfText(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: 0.36,
    ),
    displaySmall: sfText(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: 0.35,
    ),
    headlineLarge: sfText(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: 0.36,
    ),
    headlineMedium: sfText(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: 0.35,
    ),
    headlineSmall: sfText(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: 0.38,
    ),
    titleLarge: sfText(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: 0.38,
    ),
    titleMedium: sfText(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: -0.41,
    ),
    titleSmall: sfText(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: CupertinoAppColors.textSecondary,
      letterSpacing: -0.24,
    ),
    bodyLarge: sfText(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: -0.41,
    ),
    bodyMedium: sfText(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: CupertinoAppColors.textSecondary,
      letterSpacing: -0.24,
    ),
    bodySmall: sfText(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: CupertinoAppColors.textSecondary,
      letterSpacing: -0.08,
    ),
    labelLarge: sfText(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: CupertinoAppColors.textPrimary,
      letterSpacing: -0.24,
    ),
    labelMedium: sfText(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: CupertinoAppColors.textSecondary,
      letterSpacing: -0.08,
    ),
    labelSmall: sfText(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: CupertinoAppColors.textTertiary,
      letterSpacing: 0.06,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: CupertinoAppColors.purple,
      foregroundColor: CupertinoAppColors.textPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: sfText(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: CupertinoAppColors.purpleLight,
      textStyle: sfText(
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: CupertinoAppColors.groupedBackground,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: EdgeInsets.zero,
    shadowColor: Colors.transparent,
  ),
  dividerTheme: DividerThemeData(
    color: CupertinoAppColors.separator.withAlpha(80),
    thickness: 0.5,
    space: 0,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: CupertinoAppColors.background,
    indicatorColor: CupertinoAppColors.purple.withAlpha(35),
    surfaceTintColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return sfText(fontSize: 10, fontWeight: FontWeight.w700, color: CupertinoAppColors.purpleLight, letterSpacing: 0.3);
      }
      return sfText(fontSize: 10, fontWeight: FontWeight.w500, color: CupertinoAppColors.textTertiary);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: CupertinoAppColors.purpleLight, size: 20);
      }
      return IconThemeData(color: CupertinoAppColors.textTertiary, size: 20);
    }),
    height: 66,
    elevation: 0,
    overlayColor: WidgetStateProperty.all(Colors.transparent),
  ),
);
