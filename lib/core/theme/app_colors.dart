import 'package:flutter/material.dart';

/// Centralized color palette for SMET app — inspired by Coursera's
/// clean, modern aesthetic with subtle shadows and clear hierarchy.
class AppColors {
  AppColors._();

  // ─── Primary ────────────────────────────────────────────────
  static const Color primary = Color(0xFF137FEC);
  static const Color primaryLight = Color(0xFF3B8FEF);
  static const Color primaryDark = Color(0xFF0B5FC5);

  // ─── Semantic ───────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF4ADE80);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color info = Color(0xFF3B82F6);

  // ─── Accent & Gradients ────────────────────────────────────
  static const Color accentOrange = Color(0xFFFF8C42);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color gradientOrangeStart = Color(0xFFFF8C42);
  static const Color gradientOrangeEnd = Color(0xFFFF6B00);
  static const Color gradientPrimaryStart = Color(0xFF137FEC);
  static const Color gradientPrimaryEnd = Color(0xFF0B5FC5);

  // ─── Text ──────────────────────────────────────────────────
  static const Color textDark = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF475569);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textPlaceholder = Color(0xFFCBD5E1);

  // ─── Backgrounds ────────────────────────────────────────────
  static const Color bgPage = Color(0xFFF3F6FC);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgCardHover = Color(0xFFF8FAFC);
  static const Color bgInput = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF1E293B);
  static const Color bgSlate = Color(0xFF0F172A);
  static const Color bgSlateLight = Color(0xFFF1F5F9);

  // ─── Borders ───────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderFocus = Color(0xFF137FEC);

  // ─── Badge / Status backgrounds ────────────────────────────
  static const Color badgeBlueBg = Color(0xFFDBEAFE);
  static const Color badgeGreenBg = Color(0xFFDCFCE7);
  static const Color badgeYellowBg = Color(0xFFFEF3C7);
  static const Color badgeRedBg = Color(0xFFFEE2E2);
  static const Color badgeGrayBg = Color(0xFFF1F5F9);

  // ─── Shadows (subtle — Coursera-style) ───────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadowHover => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── Gradients ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientPrimaryStart, gradientPrimaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [gradientOrangeStart, gradientOrangeEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
