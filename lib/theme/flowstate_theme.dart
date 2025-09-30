import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlowstateTheme {
  static const Color primaryColor = Color(0xFF0096C7);
  static const Color secondaryColor = Color(0xFFF2C94C); 
  static const Color accentColor = Color(0xFFADE8F4); 
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF495057); 
  static const Color cardColor = Colors.white;

  static ThemeData get theme {
    final baseTheme = ThemeData.light();

    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        onSurface: textColor,
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: textColor,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          color: primaryColor,
          fontSize: 20,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        labelStyle: GoogleFonts.montserrat(color: textColor),
        prefixIconColor: primaryColor,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: textColor,
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
      ),

      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: GoogleFonts.righteous(color: primaryColor, fontSize: 48),
        headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: textColor, fontSize: 24),
        bodyLarge: GoogleFonts.montserrat(color: textColor, fontSize: 16, height: 1.5),
        bodyMedium: GoogleFonts.montserrat(color: textColor, fontSize: 14, height: 1.4),
      ).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
    );
  }
}