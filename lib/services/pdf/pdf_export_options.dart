import 'package:flutter/material.dart';

/// What the report is about. Each type decides which sections make sense.
enum PdfExportType {
  complete,
  habitProgress,
  habitHistory,
  statistics,
  todos,
  focus,
  monthly,
  yearly,
}

extension PdfExportTypeInfo on PdfExportType {
  String get label => switch (this) {
    PdfExportType.complete => 'Complete productivity report',
    PdfExportType.habitProgress => 'Habit progress report',
    PdfExportType.habitHistory => 'Habit history report',
    PdfExportType.statistics => 'Statistics report',
    PdfExportType.todos => 'To-do report',
    PdfExportType.focus => 'Focus session report',
    PdfExportType.monthly => 'Monthly summary',
    PdfExportType.yearly => 'Yearly summary',
  };

  /// Used in the file name, e.g. `FlowTracker_Habit_Progress_2026-11-10.pdf`.
  String get fileStem => switch (this) {
    PdfExportType.complete => 'Complete_Report',
    PdfExportType.habitProgress => 'Habit_Progress',
    PdfExportType.habitHistory => 'Habit_History',
    PdfExportType.statistics => 'Statistics',
    PdfExportType.todos => 'Todos',
    PdfExportType.focus => 'Focus_Sessions',
    PdfExportType.monthly => 'Monthly_Summary',
    PdfExportType.yearly => 'Yearly_Report',
  };

  /// Sections this type turns on by default.
  Set<PdfSection> get defaultSections => switch (this) {
    PdfExportType.complete => {
      PdfSection.overview,
      PdfSection.habitStats,
      PdfSection.charts,
      PdfSection.streaks,
      PdfSection.todos,
      PdfSection.focus,
    },
    PdfExportType.habitProgress => {
      PdfSection.overview,
      PdfSection.habitStats,
      PdfSection.habitDetails,
      PdfSection.charts,
    },
    PdfExportType.habitHistory => {
      PdfSection.habitDetails,
      PdfSection.completionHistory,
      PdfSection.heatmap,
    },
    PdfExportType.statistics => {
      PdfSection.overview,
      PdfSection.charts,
      PdfSection.heatmap,
      PdfSection.streaks,
    },
    PdfExportType.todos => {PdfSection.todos},
    PdfExportType.focus => {PdfSection.focus, PdfSection.charts},
    PdfExportType.monthly => {
      PdfSection.overview,
      PdfSection.habitStats,
      PdfSection.charts,
      PdfSection.heatmap,
    },
    PdfExportType.yearly => {
      PdfSection.overview,
      PdfSection.habitStats,
      PdfSection.charts,
      PdfSection.streaks,
    },
  };

  /// The natural range for a summary type, otherwise null (keep the user's).
  PdfDateRange? get naturalRange => switch (this) {
    PdfExportType.monthly => PdfDateRange.thisMonth,
    PdfExportType.yearly => PdfDateRange.thisYear,
    _ => null,
  };
}

enum PdfDateRange {
  today,
  last7,
  last30,
  thisMonth,
  lastMonth,
  thisYear,
  all,
  custom,
}

extension PdfDateRangeInfo on PdfDateRange {
  String get label => switch (this) {
    PdfDateRange.today => 'Today',
    PdfDateRange.last7 => 'Last 7 days',
    PdfDateRange.last30 => 'Last 30 days',
    PdfDateRange.thisMonth => 'This month',
    PdfDateRange.lastMonth => 'Last month',
    PdfDateRange.thisYear => 'This year',
    PdfDateRange.all => 'All history',
    PdfDateRange.custom => 'Custom range',
  };
}

/// Sections the user can include or leave out.
enum PdfSection {
  overview,
  habitStats,
  habitDetails,
  completionHistory,
  heatmap,
  streaks,
  todos,
  focus,
  charts,
  notes,
}

extension PdfSectionInfo on PdfSection {
  String get label => switch (this) {
    PdfSection.overview => 'Overview',
    PdfSection.habitStats => 'Habit statistics',
    PdfSection.habitDetails => 'Individual habits',
    PdfSection.completionHistory => 'Completion history',
    PdfSection.heatmap => 'Activity heatmap',
    PdfSection.streaks => 'Streak statistics',
    PdfSection.todos => 'To-do history',
    PdfSection.focus => 'Focus sessions',
    PdfSection.charts => 'Charts',
    PdfSection.notes => 'Notes',
  };
}

/// The six document designs. These change the actual PDF, not just the preview.
enum PdfThemeId { executive, midnight, minimal, aurora, botanical, brand }

extension PdfThemeIdInfo on PdfThemeId {
  String get label => switch (this) {
    PdfThemeId.executive => 'Executive',
    PdfThemeId.midnight => 'Midnight',
    PdfThemeId.minimal => 'Minimal',
    PdfThemeId.aurora => 'Aurora',
    PdfThemeId.botanical => 'Botanical',
    PdfThemeId.brand => 'Custom brand',
  };

  String get blurb => switch (this) {
    PdfThemeId.executive => 'White, charcoal and a muted orange accent',
    PdfThemeId.midnight => 'Graphite pages, white type, silver rules',
    PdfThemeId.minimal => 'Plain white, grey rules, no ornament',
    PdfThemeId.aurora => 'Blue and violet, editorial spacing',
    PdfThemeId.botanical => 'Soft greens on warm paper',
    PdfThemeId.brand => 'Follows your app accent colour',
  };
}

/// Everything needed to render one report.
@immutable
class PdfExportOptions {
  const PdfExportOptions({
    required this.type,
    required this.range,
    required this.sections,
    required this.theme,
    required this.accent,
    this.from,
    this.to,
  });

  final PdfExportType type;
  final PdfDateRange range;
  final Set<PdfSection> sections;
  final PdfThemeId theme;

  /// The app's current accent, used by [PdfThemeId.brand].
  final Color accent;

  /// Only meaningful for [PdfDateRange.custom].
  final DateTime? from;
  final DateTime? to;

  PdfExportOptions copyWith({
    PdfExportType? type,
    PdfDateRange? range,
    Set<PdfSection>? sections,
    PdfThemeId? theme,
    Color? accent,
    DateTime? from,
    DateTime? to,
  }) {
    return PdfExportOptions(
      type: type ?? this.type,
      range: range ?? this.range,
      sections: sections ?? this.sections,
      theme: theme ?? this.theme,
      accent: accent ?? this.accent,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }

  /// Resolves the range into concrete days, newest last. Never returns a range
  /// that ends in the future, and never one that runs backwards.
  ({DateTime from, DateTime to}) resolve(DateTime today) {
    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    final now = day(today);
    switch (range) {
      case PdfDateRange.today:
        return (from: now, to: now);
      case PdfDateRange.last7:
        return (from: now.subtract(const Duration(days: 6)), to: now);
      case PdfDateRange.last30:
        return (from: now.subtract(const Duration(days: 29)), to: now);
      case PdfDateRange.thisMonth:
        return (from: DateTime(now.year, now.month), to: now);
      case PdfDateRange.lastMonth:
        final start = DateTime(now.year, now.month - 1);
        final end = DateTime(now.year, now.month, 0);
        return (from: start, to: end);
      case PdfDateRange.thisYear:
        return (from: DateTime(now.year), to: now);
      case PdfDateRange.all:
        return (from: DateTime(2000), to: now);
      case PdfDateRange.custom:
        var start = day(from ?? now.subtract(const Duration(days: 29)));
        var end = day(to ?? now);
        if (start.isAfter(end)) {
          final swap = start;
          start = end;
          end = swap;
        }
        if (end.isAfter(now)) end = now;
        return (from: start, to: end);
    }
  }
}
