import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color flowlyPrimary = Color(0xFF7E57C2);
const Color flowlySecondary = Color(0xFFFF3366);
const Color flowlyAccent = Color(0xFF38D5E5);
const Color flowlyWarning = Color(0xFFFBC02D);
const Color flowlySuccess = Color(0xFF4CAF50);
const Color flowlyDark = Color(0xFF0D0C13);
const Color flowlyInk = Color(0xFF151522);
const Color flowlySurface = Color(0xFF14141E);
const Color flowlySurfaceAlt = Color(0xFF1B1B28);
const Color flowlyBorder = Color(0x26FFFFFF);
const Color flowlyText = Color(0xFFE8ECF7);
const Color flowlyMutedText = Color(0xFFB6BBD0);

final ThemeData flowlyTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: flowlyDark,
  canvasColor: flowlyDark,
  colorScheme: const ColorScheme.dark(
    primary: flowlyPrimary,
    secondary: flowlySecondary,
    surface: flowlySurface,
    error: flowlySecondary,
  ).copyWith(surfaceContainerHighest: flowlySurfaceAlt),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    iconTheme: const IconThemeData(color: flowlyText),
    foregroundColor: flowlyText,
    titleTextStyle: GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: flowlyText,
    ),
  ),
  textTheme: GoogleFonts.outfitTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: flowlyText,
      letterSpacing: -0.4,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: flowlyText,
      letterSpacing: -0.3,
    ),
    headlineLarge: GoogleFonts.outfit(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: flowlyText,
      letterSpacing: -0.2,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: flowlyText,
    ),
    titleLarge: GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: flowlyText,
    ),
    titleMedium: GoogleFonts.outfit(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: flowlyText,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: flowlyText,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: flowlyMutedText,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: flowlyMutedText,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: flowlyText,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0x1AFFFFFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: flowlyMutedText,
    ),
    hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0x80E8ECF7)),
    helperStyle: GoogleFonts.inter(fontSize: 12, color: flowlyMutedText),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: flowlyBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: flowlyBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: flowlyPrimary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: flowlySecondary),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: flowlySecondary, width: 1.6),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: flowlyPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: flowlyText,
      side: const BorderSide(color: flowlyBorder),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: flowlySecondary,
      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: flowlySecondary,
    foregroundColor: Colors.white,
    elevation: 4,
    shape: CircleBorder(),
  ),
  cardTheme: CardThemeData(
    color: const Color(0x1AFFFFFF),
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: flowlyBorder),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0x1AFFFFFF),
    selectedColor: flowlyPrimary,
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: flowlyText,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
  ),
  dividerTheme: const DividerThemeData(color: flowlyBorder, thickness: 1),
);
