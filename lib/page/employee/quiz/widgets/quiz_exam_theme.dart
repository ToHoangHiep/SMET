import 'package:flutter/material.dart';

/// Quiz Exam Theme - Material 3 inspired design
/// Colors mapped from the HTML Tailwind config (Material 3)
class QuizExamTheme {
  // ── Primary palette (Material 3 blue) ──────────────────────────────
  static const Color primary = Color(0xFF005baf);       // primary
  static const Color primaryContainer = Color(0xFF0074db); // primary-container
  static const Color onPrimary = Color(0xFFffffff);
  static const Color onPrimaryContainer = Color(0xFFfefcff);
  static const Color primaryFixed = Color(0xFFd5e3ff);
  static const Color primaryFixedDim = Color(0xFFa8c8ff);
  static const Color onPrimaryFixed = Color(0xFF001b3c);
  static const Color onPrimaryFixedVariant = Color(0xFF004689);

  // ── Secondary palette ──────────────────────────────────────────────
  static const Color secondary = Color(0xFF455f89);
  static const Color secondaryContainer = Color(0xFFb2cdfd);
  static const Color onSecondary = Color(0xFFffffff);
  static const Color onSecondaryContainer = Color(0xFF3c5780);
  static const Color secondaryFixed = Color(0xFFd5e3ff);
  static const Color secondaryFixedDim = Color(0xFFadc8f7);
  static const Color onSecondaryFixed = Color(0xFF001b3c);
  static const Color onSecondaryFixedVariant = Color(0xFF2c4770);

  // ── Tertiary palette ───────────────────────────────────────────────
  static const Color tertiary = Color(0xFF964400);
  static const Color tertiaryContainer = Color(0xFFbc5700);
  static const Color onTertiary = Color(0xFFffffff);
  static const Color onTertiaryContainer = Color(0xFFfffbff);
  static const Color tertiaryFixed = Color(0xFFffdbc9);
  static const Color tertiaryFixedDim = Color(0xFFffb68c);
  static const Color onTertiaryFixed = Color(0xFF321200);
  static const Color onTertiaryFixedVariant = Color(0xFF753400);

  // ── Surface / Background ──────────────────────────────────────────
  static const Color background = Color(0xFFf9f9ff);
  static const Color surface = Color(0xFFf9f9ff);
  static const Color surfaceBright = Color(0xFFf9f9ff);
  static const Color surfaceDim = Color(0xFFd7dae3);
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  static const Color surfaceContainerLow = Color(0xFFf1f3fd);
  static const Color surfaceContainer = Color(0xFFebedf7);
  static const Color surfaceContainerHigh = Color(0xFFe6e8f1);
  static const Color surfaceContainerHighest = Color(0xFFe0e2ec);
  static const Color surfaceVariant = Color(0xFFe0e2ec);
  static const Color surfaceTint = Color(0xFF005eb4);

  // ── On-surface ────────────────────────────────────────────────────
  static const Color onBackground = Color(0xFF181c22);
  static const Color onSurface = Color(0xFF181c22);
  static const Color onSurfaceVariant = Color(0xFF414753);
  static const Color inverseSurface = Color(0xFF2d3038);
  static const Color inverseOnSurface = Color(0xFFeef0fa);
  static const Color inversePrimary = Color(0xFFa8c8ff);

  // ── Outline / Dividers ────────────────────────────────────────────
  static const Color outline = Color(0xFF717785);
  static const Color outlineVariant = Color(0xFFc1c6d5);

  // ── Semantic colors ───────────────────────────────────────────────
  static const Color error = Color(0xFFba1a1a);
  static const Color errorContainer = Color(0xFFffdad6);
  static const Color onError = Color(0xFFffffff);
  static const Color onErrorContainer = Color(0xFF93000a);

  // ── Legacy / convenience aliases (kept for existing code) ─────────
  static const Color primaryTeal = primaryContainer;     // teal → primary-container
  static const Color primaryBlue = primary;               // blue → primary
  static const Color backgroundGray = surfaceContainerLow;
  static const Color cardWhite = surfaceContainerLowest;
  static const Color divider = outlineVariant;
  static const Color textDark = onSurface;
  static const Color textGray = onSurfaceVariant;
  static const Color answeredGreen = Color(0xFF10B981);
  static const Color flaggedOrange = tertiary;
  static const Color currentBorder = primary;
  static const Color unanswerGray = surfaceContainerHighest;
  static const Color correctGreen = Color(0xFF22C55E);
  static const Color wrongRed = error;

  // ── Border Radius ─────────────────────────────────────────────────
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius gridItemRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(9999));

  // ── Shadows ──────────────────────────────────────────────────────
  static BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 12,
    offset: const Offset(0, 2),
  );

  static BoxShadow get cardShadowLight => BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 8,
    offset: const Offset(0, 1),
  );

  static BoxShadow get cardShadowMedium => BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );
}

enum QuestionDisplayMode {
  single,
  multiple,
  trueFalse,
}
