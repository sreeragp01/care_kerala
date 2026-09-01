import 'package:flutter/material.dart';

/// CareLink Kerala Official Brand Palette & Theme Colors
///
/// Design System:
/// 1. Trust (#0A4D8C) - Deep Navy Marine Blue for authority, primary actions, and headers
/// 2. Care (#00BFA6) - Vibrant Cyan-Teal for care coordination, interactive accents, and badges
/// 3. Health (#34D399) - Luminous Emerald Green for vital metrics, success states, and recovery
/// 4. Peace (#E3F2FD) - Soft Sky Blue for calming surfaces, chips, and container backgrounds
/// 5. High-Contrast Text: Pure solid black/slate in bright mode, crisp white/ice-blue in dark mode
class AppColors {
  // --- Official 4-Color Brand Palette ---
  static const Color brandNavy = Color(0xFF0A4D8C); // Trust (Deep Marine Blue)
  static const Color brandTeal = Color(0xFF00BFA6); // Care (Vibrant Cyan-Teal)
  static const Color brandHealthGreen = Color(0xFF34D399); // Health (Luminous Emerald)
  static const Color brandPeaceBlue = Color(0xFFE3F2FD); // Peace (Soft Sky Blue)

  // --- Dark Mode Brand Canvas & Gradients ---
  static const Color brandSplashDark = Color(0xFF051E34); // Deep Brand Navy Canvas
  static const Color brandSplashNavy = Color(0xFF082742); // Elevated Navy Gradient

  // --- Bright (Light) Mode Palette ---
  static const Color primaryGreen = Color(0xFF00BFA6); // Care Teal (Main Brand Color)
  static const Color secondaryGreen = Color(0xFF0A4D8C); // Trust Navy
  static const Color lightGreenSurface = Color(0xFFE3F2FD); // Peace Blue Tint Surface
  static const Color emeraldGlow = Color(0xFF34D399); // Health Luminous Mint Glow

  // Accent Gold & Warmth
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentGoldLight = Color(0xFFFEF3C7);

  // Backgrounds & Canvas (Light Theme)
  static const Color background = Color(0xFFF8FAFC); // Clean Slate Canvas
  static const Color surface = Color(0xFFFFFFFF); // Crisp White Surface
  static const Color glassSurface = Color(0x280A4D8C); // Translucent Navy Rim
  static const Color lightSand = Color(0xFFE3F2FD); // Peace Blue Tint
  static const Color cardBorder = Color(0xFFD6E4F0); // Subtle Peace Border

  // High-Contrast Text Colors (Light Mode: Solid Black/Dark Slate)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 (Pure Crisp Dark)
  static const Color textSecondary = Color(0xFF334155); // Slate 700 (High Contrast)
  static const Color textLight = Color(0xFF64748B); // Slate 500

  // System & Alert Colors
  static const Color danger = Color(0xFFEF4444); // Emergency Crimson
  static const Color dangerSurface = Color(0xFFFFECEF);
  static const Color warning = Color(0xFFF59E0B); // Warm Amber
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color success = Color(0xFF10B981); // Emerald Success
  static const Color successSurface = Color(0xFFE6F4EE);
  static const Color info = Color(0xFF0A4D8C); // Trust Navy Info
  static const Color infoSurface = Color(0xFFE3F2FD);

  // --- Dark Mode Palette (Deep Navy Glassmorphism) ---
  static const Color darkBackground = Color(0xFF051E34); // Deep Navy Canvas
  static const Color darkSurface = Color(0xFF0A2946); // Dark Navy Glass Card
  static const Color darkSurfaceLight = Color(0xFF0E385D); // Elevated Navy Surface
  static const Color darkCardBorder = Color(0x3800BFA6); // Luminous Cyan-Teal Border
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Pure Crisp White Text
  static const Color darkTextSecondary = Color(0xFFE3F2FD); // Ice Blue Secondary Text
  static const Color darkTextLight = Color(0xFFA7F3D0); // Mint Accent Text
  static const Color darkPrimaryGreen = Color(0xFF00BFA6); // Radiant Care Teal
  static const Color darkSecondaryGreen = Color(0xFF34D399); // Health Emerald Green
  static const Color darkLightGreenSurface = Color(0xFF093748); // Dark Teal Tint Surface
  static const Color darkDangerSurface = Color(0xFF3B1219);
  static const Color darkWarningSurface = Color(0xFF3B2A0F);
  static const Color darkInfoSurface = Color(0xFF07263F);

  // Common Theme Aliases
  static const Color emerald = Color(0xFF34D399);
  static const Color emeraldLight = Color(0xFF6EE7B7);
  static const Color secondary = Color(0xFF00BFA6);
  static const Color primary = Color(0xFF0A4D8C);
}
