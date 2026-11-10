import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flow_tracker/services/pdf/pdf_export_options.dart';

/// The palette and typography one PDF is drawn with. Six of these ship, and
/// they change the real document — background, ink, rules, accent and chart
/// colours — not just a preview swatch.
class PdfTheme {
  const PdfTheme({
    required this.id,
    required this.page,
    required this.ink,
    required this.muted,
    required this.rule,
    required this.card,
    required this.accent,
    required this.accentSoft,
    required this.dark,
  });

  final PdfThemeId id;
  final PdfColor page;
  final PdfColor ink;
  final PdfColor muted;
  final PdfColor rule;
  final PdfColor card;
  final PdfColor accent;
  final PdfColor accentSoft;
  final bool dark;

  static PdfColor _c(int argb) => PdfColor.fromInt(argb);

  /// The same palette as Flutter colours, for the theme cards in the app. The
  /// PDF never uses these; it uses the [PdfColor] fields above.
  static PdfThemeUi ui(PdfThemeId id, Color accent) {
    final theme = of(id, accent);
    Color ui(PdfColor colour) => Color(colour.toInt());
    return PdfThemeUi(
      page: ui(theme.page),
      ink: ui(theme.ink),
      accent: ui(theme.accent),
      rule: ui(theme.rule),
      muted: ui(theme.muted),
    );
  }

  /// Builds the theme for [id]. [accent] is the app's accent colour and is only
  /// used by [PdfThemeId.brand]; every other theme keeps its own identity.
  static PdfTheme of(PdfThemeId id, Color accent) {
    switch (id) {
      case PdfThemeId.executive:
        return PdfTheme(
          id: id,
          page: _c(0xFFFFFFFF),
          ink: _c(0xFF1F2328),
          muted: _c(0xFF6B7280),
          rule: _c(0xFFE5E7EB),
          card: _c(0xFFF6F7F9),
          accent: _c(0xFFB45309),
          accentSoft: _c(0xFFFDE8D7),
          dark: false,
        );
      case PdfThemeId.midnight:
        return PdfTheme(
          id: id,
          page: _c(0xFF14161A),
          ink: _c(0xFFF4F5F7),
          muted: _c(0xFF9CA3AF),
          rule: _c(0xFF2C3037),
          card: _c(0xFF1C1F25),
          accent: _c(0xFFF59E0B),
          accentSoft: _c(0xFF2A2118),
          dark: true,
        );
      case PdfThemeId.minimal:
        return PdfTheme(
          id: id,
          page: _c(0xFFFFFFFF),
          ink: _c(0xFF111111),
          muted: _c(0xFF8A8A8A),
          rule: _c(0xFFE0E0E0),
          card: _c(0xFFFFFFFF),
          accent: _c(0xFF111111),
          accentSoft: _c(0xFFF2F2F2),
          dark: false,
        );
      case PdfThemeId.aurora:
        return PdfTheme(
          id: id,
          page: _c(0xFFFBFBFE),
          ink: _c(0xFF1E1B4B),
          muted: _c(0xFF6366F1),
          rule: _c(0xFFE0E7FF),
          card: _c(0xFFF3F1FF),
          accent: _c(0xFF6D28D9),
          accentSoft: _c(0xFFE9E2FF),
          dark: false,
        );
      case PdfThemeId.botanical:
        return PdfTheme(
          id: id,
          page: _c(0xFFFAFAF7),
          ink: _c(0xFF1F2A24),
          muted: _c(0xFF5F6F65),
          rule: _c(0xFFDCE5DC),
          card: _c(0xFFF1F5EF),
          accent: _c(0xFF2F7A4F),
          accentSoft: _c(0xFFDFEDE2),
          dark: false,
        );
      case PdfThemeId.brand:
        final base = _c(accent.toARGB32());
        return PdfTheme(
          id: id,
          page: _c(0xFFFFFFFF),
          ink: _c(0xFF1A1A1E),
          muted: _c(0xFF6E6E76),
          rule: _c(0xFFE6E6EA),
          card: _c(0xFFF7F7FA),
          accent: base,
          accentSoft: _c(0xFFEDEBF6),
          dark: false,
        );
    }
  }
}

/// Type scale and shared pieces. Kept in one place so every report looks like it
/// came from the same design system.
class PdfStyle {
  PdfStyle(this.theme, {required pw.Font base, required pw.Font bold})
    : _base = base,
      _bold = bold;

  final PdfTheme theme;
  final pw.Font _base;
  final pw.Font _bold;

  pw.ThemeData get documentTheme =>
      pw.ThemeData.withFont(base: _base, bold: _bold);

  pw.TextStyle get coverTitle => pw.TextStyle(
    font: _bold,
    fontSize: 30,
    color: theme.ink,
    lineSpacing: 3,
  );

  pw.TextStyle get wordmark => pw.TextStyle(
    font: _bold,
    fontSize: 15,
    color: theme.ink,
    letterSpacing: 0.2,
  );

  pw.TextStyle get lead => pw.TextStyle(
    font: _base,
    fontSize: 11,
    color: theme.muted,
    lineSpacing: 3,
  );

  pw.TextStyle get h1 => pw.TextStyle(
    font: _bold,
    fontSize: 18.5,
    color: theme.ink,
    lineSpacing: 2,
  );

  pw.TextStyle get h2 => pw.TextStyle(
    font: _bold,
    fontSize: 13,
    color: theme.ink,
  );

  pw.TextStyle get body => pw.TextStyle(
    font: _base,
    fontSize: 10,
    color: theme.ink,
    lineSpacing: 1.6,
  );

  pw.TextStyle get small => pw.TextStyle(
    font: _base,
    fontSize: 9,
    color: theme.muted,
    lineSpacing: 1.4,
  );

  pw.TextStyle get table => pw.TextStyle(
    font: _base,
    fontSize: 8.5,
    color: theme.ink,
  );

  pw.TextStyle get caption => pw.TextStyle(
    font: _base,
    fontSize: 8,
    color: theme.muted,
  );

  pw.TextStyle get metaLabel => pw.TextStyle(
    font: _bold,
    fontSize: 7.5,
    color: theme.muted,
    letterSpacing: 0.6,
  );

  pw.TextStyle get footer => pw.TextStyle(
    font: _base,
    fontSize: 7.5,
    color: theme.muted,
  );

  pw.TextStyle get stat => pw.TextStyle(
    font: _bold,
    fontSize: 19,
    color: theme.ink,
  );

  pw.TextStyle get accentStat => pw.TextStyle(
    font: _bold,
    fontSize: 20,
    color: theme.accent,
  );
}

/// Flutter-side view of a [PdfTheme], so the picker can draw the same colours
/// the document will use.
class PdfThemeUi {
  const PdfThemeUi({
    required this.page,
    required this.ink,
    required this.accent,
    required this.rule,
    required this.muted,
  });

  final Color page;
  final Color ink;
  final Color accent;
  final Color rule;
  final Color muted;
}
