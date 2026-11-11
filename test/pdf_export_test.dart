import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tracker/features/habits/data/habit.dart';
import 'package:flow_tracker/services/pdf/pdf_export_options.dart';
import 'package:flow_tracker/services/pdf/pdf_export_service.dart';
import 'package:flow_tracker/services/pdf/pdf_report_data.dart';

import 'support/app_harness.dart';

/// A PDF that has actually been written has these markers. Object streams are
/// compressed, so the only cheap structural checks are the header, the trailer
/// and a size floor; the content itself was verified with an external parser.
void expectRealPdf(Uint8List bytes, {String? reason}) {
  expect(
    String.fromCharCodes(bytes.take(5)),
    '%PDF-',
    reason: reason ?? 'missing PDF header',
  );
  expect(
    String.fromCharCodes(bytes.skip(bytes.length - 8)).trim(),
    endsWith('%%EOF'),
    reason: reason ?? 'missing PDF trailer',
  );
  expect(
    bytes.length,
    greaterThan(2000),
    reason: reason ?? 'suspiciously small',
  );
}

void main() {
  useEmptyStore();

  // Everything below is relative to the real clock: the fixtures seed data from
  // AppClock.now(), so a fixed date here would make the suite fail the next day.
  final _now = DateTime.now();
  final today = DateTime(_now.year, _now.month, _now.day);
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));
  String two(int v) => v.toString().padLeft(2, '0');
  String key(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  PdfExportOptions optionsFor(
    PdfExportType type, {
    PdfThemeId theme = PdfThemeId.executive,
    PdfDateRange range = PdfDateRange.last30,
    Set<PdfSection>? sections,
    Color accent = const Color(0xFF7C3AED),
  }) => PdfExportOptions(
    type: type,
    range: range,
    sections: sections ?? {...type.defaultSections},
    theme: theme,
    accent: accent,
  );

  Future<void> seed(WidgetTester tester) async {
    final days = lastDays(6);
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', done: days),
      testHabit(id: 'b', name: 'Water', done: days.take(3).toList()),
    ]);
  }

  testWidgets('every export type and every theme makes a real PDF', (
    tester,
  ) async {
    await seed(tester);
    final seen = <String>{};
    for (final type in PdfExportType.values) {
      for (final theme in PdfThemeId.values) {
        final bytes = await tester.runAsync(
          () => PdfExportService.generate(
            optionsFor(type, theme: theme),
            today: today,
            version: 'test',
          ),
        );
        final name = '${type.name}/${theme.name}';
        expectRealPdf(bytes!, reason: name);
        // no two of the 48 documents may be the same file
        expect(seen.add(bytes.toString()), isTrue, reason: 'duplicate $name');
      }
    }
    expect(seen.length, PdfExportType.values.length * PdfThemeId.values.length);
  });

  testWidgets('the theme changes the document, not just its name', (
    tester,
  ) async {
    await seed(tester);
    final light = await tester.runAsync(
      () => PdfExportService.generate(
        optionsFor(PdfExportType.complete, theme: PdfThemeId.executive),
        today: today,
      ),
    );
    final dark = await tester.runAsync(
      () => PdfExportService.generate(
        optionsFor(PdfExportType.complete, theme: PdfThemeId.midnight),
        today: today,
      ),
    );
    expect(light, isNot(equals(dark)));
  });

  testWidgets('the custom brand theme follows the app accent', (tester) async {
    await seed(tester);
    final violet = await tester.runAsync(
      () => PdfExportService.generate(
        optionsFor(PdfExportType.statistics, theme: PdfThemeId.brand),
        today: today,
      ),
    );
    final orange = await tester.runAsync(
      () => PdfExportService.generate(
        optionsFor(
          PdfExportType.statistics,
          theme: PdfThemeId.brand,
          accent: const Color(0xFFF97316),
        ),
        today: today,
      ),
    );
    expect(violet, isNot(equals(orange)));
  });

  testWidgets('only the chosen sections are drawn', (tester) async {
    await seed(tester);
    final everything = await tester.runAsync(
      () => PdfExportService.generate(
        optionsFor(PdfExportType.complete),
        today: today,
      ),
    );
    final todosOnly = await tester.runAsync(
      () => PdfExportService.generate(
        optionsFor(
          PdfExportType.complete,
          sections: {PdfSection.todos},
        ),
        today: today,
      ),
    );
    expectRealPdf(todosOnly!);
    expect(todosOnly.length, lessThan(everything!.length));
  });

  testWidgets('an empty database still produces a readable report', (
    tester,
  ) async {
    final bytes = await tester.runAsync(
      () => PdfExportService.generate(
        optionsFor(PdfExportType.complete),
        today: today,
      ),
    );
    expectRealPdf(bytes!);
  });

  group('date ranges', () {
    test('resolve to the days they say they do', () {
      final o = optionsFor(PdfExportType.complete);
      expect(o.copyWith(range: PdfDateRange.today).resolve(today), (
        from: today,
        to: today,
      ));
      expect(o.copyWith(range: PdfDateRange.last7).resolve(today), (
        from: daysAgo(6),
        to: today,
      ));
      expect(o.copyWith(range: PdfDateRange.last30).resolve(today), (
        from: daysAgo(29),
        to: today,
      ));
      expect(o.copyWith(range: PdfDateRange.thisMonth).resolve(today), (
        from: DateTime(today.year, today.month, 1),
        to: today,
      ));
      final lastMonthEnd = DateTime(
        today.year,
        today.month,
        1,
      ).subtract(const Duration(days: 1));
      expect(o.copyWith(range: PdfDateRange.lastMonth).resolve(today), (
        from: DateTime(lastMonthEnd.year, lastMonthEnd.month, 1),
        to: lastMonthEnd,
      ));
      expect(o.copyWith(range: PdfDateRange.thisYear).resolve(today), (
        from: DateTime(today.year, 1, 1),
        to: today,
      ));
    });

    test('a custom range is swapped when backwards and clamped to today', () {
      final o = optionsFor(PdfExportType.complete);
      final swapped = o
          .copyWith(
            range: PdfDateRange.custom,
            from: daysAgo(2),
            to: daysAgo(8),
          )
          .resolve(today);
      expect(swapped.from, daysAgo(8));
      expect(swapped.to, daysAgo(2));

      final future = o
          .copyWith(
            range: PdfDateRange.custom,
            from: daysAgo(10),
            to: today.add(const Duration(days: 30)),
          )
          .resolve(today);
      expect(future.to, today);
    });
  });

  group('file names', () {
    test('are meaningful per report type', () {
      String name(PdfExportType type) =>
          PdfExportService.fileName(optionsFor(type), today: today);
      expect(
        name(PdfExportType.complete),
        'FlowTracker_Complete_Report_${key(today)}.pdf',
      );
      expect(
        name(PdfExportType.habitProgress),
        'FlowTracker_Habit_Progress_${key(today)}.pdf',
      );
      expect(
        name(PdfExportType.monthly),
        'FlowTracker_Monthly_Summary_${today.year}-${two(today.month)}.pdf',
      );
      expect(
        name(PdfExportType.yearly),
        'FlowTracker_Yearly_Report_${today.year}.pdf',
      );
      expect(name(PdfExportType.todos), endsWith('.pdf'));
      expect(name(PdfExportType.todos), contains('FlowTracker_'));
    });
  });

  testWidgets('the numbers in the report come from the records', (
    tester,
  ) async {
    final days = lastDays(4); // today, -1, -2, -3
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', done: days),
      testHabit(id: 'b', name: 'Water', done: days.take(2).toList()),
    ]);

    final data = ReportData.load(
      from: today.subtract(const Duration(days: 9)),
      to: today,
      today: today,
    );

    expect(data.totalHabits, 2);
    // both habits are daily, so 10 scheduled days each over the window
    expect(data.scheduledTotal, 20);
    expect(data.completedTotal, 6);
    expect(data.percent, closeTo(0.3, 0.001));
    expect(data.trackedDays, 4);
    expect(data.habits.first.completed, greaterThanOrEqualTo(2));
    expect(data.peakDay, 2);
    expect(data.isEmpty, isFalse);
  });

  testWidgets('habits are only counted on the days they run', (tester) async {
    // a habit scheduled only on Mondays should not be marked down for other days
    await seedHabits(tester, [
      testHabit(
        id: 'w',
        name: 'Weekly review',
        interval: HabitInterval.weekdays,
        scheduleWeekdays: const [1],
        done: lastDays(1),
      ),
    ]);
    final data = ReportData.load(
      from: today.subtract(const Duration(days: 27)),
      to: today,
      today: today,
    );
    expect(data.totalHabits, 1);
    expect(data.scheduledTotal, lessThan(10));
    expect(data.scheduledTotal, greaterThan(0));
  });

  test('the PDF code cannot reach the network', () {
    // The offline promise is structural: nothing in the export path may import
    // an HTTP client. This test fails the day someone adds one.
    final files = Directory(
      'lib/services/pdf',
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final forbidden in [
        'package:http/',
        'dart:io" show Socket',
        'HttpClient',
        'package:dio/',
        'package:web_socket',
      ]) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: '${file.path} imports $forbidden',
        );
      }
    }
  });
  group('the calculation bugs from the reported screenshot', () {
    testWidgets(
      'all history starts at the first real record, not the year 2000',
      (
        tester,
      ) async {
        await seedHabits(tester, [
          testHabit(id: 'a', name: 'Read', daysOld: 5, done: lastDays(2)),
        ]);
        final data = ReportData.load(
          from: DateTime(2000),
          to: today,
          today: today,
        );
        // a habit created five days ago cannot have a 9,000-day denominator
        expect(data.from.isAfter(DateTime(2000)), isTrue);
        expect(data.from, today.subtract(const Duration(days: 5)));
        expect(data.scheduledTotal, lessThan(30));
      },
    );

    testWidgets('a habit is only counted from the day it was created', (
      tester,
    ) async {
      await seedHabits(tester, [
        testHabit(id: 'new', name: 'New habit', daysOld: 3, done: lastDays(1)),
      ]);
      final data = ReportData.load(
        from: today.subtract(const Duration(days: 29)),
        to: today,
        today: today,
      );
      // 4 days exist (creation day to today), not 30
      expect(data.habits.single.scheduled, 4);
      expect(data.habits.single.completed, 1);
    });

    testWidgets('one completion is not reported as 0%', (tester) async {
      await seedHabits(tester, [
        testHabit(id: 'a', name: 'Read', daysOld: 0, done: lastDays(1)),
      ]);
      final data = ReportData.load(from: today, to: today, today: today);
      expect(data.scheduledTotal, 1);
      expect(data.completedTotal, 1);
      expect(data.percent, 1.0);
      expect(data.trackedDays, 1);
      expect(data.days, 1);
    });

    testWidgets('tracked days never exceed the days in the period', (
      tester,
    ) async {
      await seedHabits(tester, [
        testHabit(id: 'a', name: 'Read', daysOld: 90, done: lastDays(40)),
      ]);
      final data = ReportData.load(
        from: today.subtract(const Duration(days: 9)),
        to: today,
        today: today,
      );
      expect(data.trackedDays, lessThanOrEqualTo(data.days));
      expect(data.trackedDays, 10);
    });

    testWidgets('completions on unscheduled days are counted as entries only', (
      tester,
    ) async {
      // a Monday-only habit completed on a day that is not Monday
      var otherDay = today;
      while (otherDay.weekday == DateTime.monday) {
        otherDay = otherDay.subtract(const Duration(days: 1));
      }
      await seedHabits(tester, [
        testHabit(
          id: 'w',
          name: 'Weekly review',
          daysOld: 60,
          interval: HabitInterval.weekdays,
          scheduleWeekdays: const [1],
          done: [otherDay],
        ),
      ]);
      final data = ReportData.load(
        from: today.subtract(const Duration(days: 6)),
        to: today,
        today: today,
      );
      expect(data.entries, 1);
      expect(data.completedTotal, 0);
      expect(data.habits.single.entries, 1);
    });
  });
}
