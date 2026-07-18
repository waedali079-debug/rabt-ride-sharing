import 'package:flutter/material.dart';
import '../constants/design_constants.dart';

class RabtTheme {
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(RabtDesignConstants.primaryLight),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(RabtDesignConstants.bgPrimaryLight),
      fontFamily: 'Tajawal',
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(RabtDesignConstants.bgPrimaryLight),
        foregroundColor: const Color(RabtDesignConstants.textPrimaryLight),
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(RabtDesignConstants.primaryLight),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, RabtDesignConstants.buttonHeightPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RabtDesignConstants.radiusCapsule),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(RabtDesignConstants.primaryLight),
          minimumSize: const Size(double.infinity, RabtDesignConstants.buttonHeightSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RabtDesignConstants.radiusCapsule),
            side: const BorderSide(color: Color(RabtDesignConstants.primaryLight)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RabtDesignConstants.radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RabtDesignConstants.spaceMd,
          vertical: RabtDesignConstants.spaceSm,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RabtDesignConstants.radiusMd),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(RabtDesignConstants.primaryDark),
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(RabtDesignConstants.bgPrimaryDark),
      fontFamily: 'Tajawal',
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(RabtDesignConstants.bgPrimaryDark),
        foregroundColor: const Color(RabtDesignConstants.textPrimaryDark),
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(RabtDesignConstants.primaryDark),
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, RabtDesignConstants.buttonHeightPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RabtDesignConstants.radiusCapsule),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(RabtDesignConstants.primaryDark),
          minimumSize: const Size(double.infinity, RabtDesignConstants.buttonHeightSecondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RabtDesignConstants.radiusCapsule),
            side: const BorderSide(color: Color(RabtDesignConstants.primaryDark)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RabtDesignConstants.radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: RabtDesignConstants.spaceMd,
          vertical: RabtDesignConstants.spaceSm,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RabtDesignConstants.radiusMd),
        ),
      ),
    );
  }
}
