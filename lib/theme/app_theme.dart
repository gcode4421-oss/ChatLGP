import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// نظام الألوان والثيم للتطبيق — مستوحى من تصميمات Material 3 الحديثة
/// مع لمسات احترافية تشبه تطبيقات Claude/ChatGPT

class AppTheme {
  // الألوان الأساسية
  static const Color _primaryLight = Color(0xFF6366F1); // Indigo
  static const Color _primaryDark = Color(0xFF818CF8);
  static const Color _accent = Color(0xFFEC4899); // Pink
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _error = Color(0xFFEF4444);

  // ألوان الخلفية للوضع الفاتح
  static const Color _bgLight = Color(0xFFFAFAFA);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _cardLight = Color(0xFFF5F5F7);

  // ألوان الخلفية للوضع الداكن
  static const Color _bgDark = Color(0xFF0F0F1A);
  static const Color _surfaceDark = Color(0xFF1A1A2E);
  static const Color _cardDark = Color(0xFF23233B);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryLight,
      brightness: Brightness.light,
      primary: _primaryLight,
      secondary: _accent,
      surface: _surfaceLight,
      error: _error,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgLight,
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceLight,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.cairo(fontSize: 16, color: const Color(0xFF1A1A2E)),
        bodyMedium: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF4B5563)),
        titleLarge: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
        labelLarge: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardTheme(
        color: _cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryLight,
          side: const BorderSide(color: _primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconTheme: const IconThemeData(color: _primaryLight, size: 24),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _surfaceLight,
        selectedItemColor: _primaryLight,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
      ),
      extensions: [
        AppColorsExtension(
          success: _success,
          warning: _warning,
          bubbleUser: const Color(0xFF6366F1),
          bubbleAssistant: const Color(0xFFF5F5F7),
          bubbleUserText: Colors.white,
          bubbleAssistantText: const Color(0xFF1A1A2E),
          codeBlockBg: const Color(0xFFF1F5F9),
          thinkingColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryDark,
      brightness: Brightness.dark,
      primary: _primaryDark,
      secondary: _accent,
      surface: _surfaceDark,
      error: _error,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgDark,
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
        bodyMedium: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade300),
        titleLarge: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        labelLarge: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardTheme(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: const Color(0xFF0F0F1A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryDark,
          side: const BorderSide(color: _primaryDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconTheme: const IconThemeData(color: _primaryDark, size: 24),
      dividerTheme: DividerThemeData(color: Colors.grey.shade800, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _surfaceDark,
        selectedItemColor: _primaryDark,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
      ),
      extensions: [
        AppColorsExtension(
          success: _success,
          warning: _warning,
          bubbleUser: const Color(0xFF6366F1),
          bubbleAssistant: const Color(0xFF23233B),
          bubbleUserText: Colors.white,
          bubbleAssistantText: Colors.white,
          codeBlockBg: const Color(0xFF0D1117),
          thinkingColor: const Color(0xFFA78BFA),
        ),
      ],
    );
  }
}

/// ألوان إضافية مخصصة تُستخدم عبر [ThemeExtension]
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color success;
  final Color warning;
  final Color bubbleUser;
  final Color bubbleAssistant;
  final Color bubbleUserText;
  final Color bubbleAssistantText;
  final Color codeBlockBg;
  final Color thinkingColor;

  const AppColorsExtension({
    required this.success,
    required this.warning,
    required this.bubbleUser,
    required this.bubbleAssistant,
    required this.bubbleUserText,
    required this.bubbleAssistantText,
    required this.codeBlockBg,
    required this.thinkingColor,
  });

  @override
  AppColorsExtension copyWith({
    Color? success,
    Color? warning,
    Color? bubbleUser,
    Color? bubbleAssistant,
    Color? bubbleUserText,
    Color? bubbleAssistantText,
    Color? codeBlockBg,
    Color? thinkingColor,
  }) =>
      AppColorsExtension(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        bubbleUser: bubbleUser ?? this.bubbleUser,
        bubbleAssistant: bubbleAssistant ?? this.bubbleAssistant,
        bubbleUserText: bubbleUserText ?? this.bubbleUserText,
        bubbleAssistantText: bubbleAssistantText ?? this.bubbleAssistantText,
        codeBlockBg: codeBlockBg ?? this.codeBlockBg,
        thinkingColor: thinkingColor ?? this.thinkingColor,
      );

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) =>
      AppColorsExtension(
        success: Color.lerp(success, other?.success, t)!,
        warning: Color.lerp(warning, other?.warning, t)!,
        bubbleUser: Color.lerp(bubbleUser, other?.bubbleUser, t)!,
        bubbleAssistant: Color.lerp(bubbleAssistant, other?.bubbleAssistant, t)!,
        bubbleUserText: Color.lerp(bubbleUserText, other?.bubbleUserText, t)!,
        bubbleAssistantText: Color.lerp(bubbleAssistantText, other?.bubbleAssistantText, t)!,
        codeBlockBg: Color.lerp(codeBlockBg, other?.codeBlockBg, t)!,
        thinkingColor: Color.lerp(thinkingColor, other?.thinkingColor, t)!,
      );

  static AppColorsExtension of(BuildContext context) =>
      Theme.of(context).extension<AppColorsExtension>()!;
}
