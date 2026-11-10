import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flow_tracker/services/pdf/pdf_export_options.dart';
import 'package:flow_tracker/services/pdf/pdf_report_data.dart';
import 'package:flow_tracker/services/pdf/pdf_theme.dart';

/// Turns aggregated [ReportData] into a real PDF document.
///
/// Everything here is pure: no storage, no plugins, no network. The caller
/// supplies the data and the fonts, which is what makes the output testable and
/// guaranteed to work offline.
class PdfReportBuilder {
  PdfReportBuilder({
    required this.options,
    required this.data,
    required this.style,
    required this.generatedAt,
    required this.version,
  });

  final PdfExportOptions options;
  final ReportData data;
  final PdfStyle style;
  final DateTime generatedAt;
  final String version;

  static const _pageFormat = PdfPageFormat.a4;
  static const _margin = 38.0;

  PdfTheme get theme => style.theme;

  pw.Document build() {
    final doc = pw.Document(
      title: '${options.type.label} — Flow-tracker',
      author: 'Umaiz Sufiyan',
      creator: 'Flow-tracker $version',
      subject: _period(),
    );
    doc.addPage(_cover());
    doc.addPage(_body());
    return doc;
  }

  // ---------------------------------------------------------------- helpers

  String _d(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  String _period() {
    if (_d(data.from) == _d(data.to)) return _d(data.from);
    return '${_d(data.from)} to ${_d(data.to)}';
  }

  String _percent(double value) => '${(value * 100).round()}%';

  pw.PageTheme get _pageTheme => pw.PageTheme(
    pageFormat: _pageFormat,
    margin: const pw.EdgeInsets.fromLTRB(_margin, 44, _margin, 46),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Container(color: theme.page),
    ),
  );

  pw.Widget _rule({double thickness = 0.6}) =>
      pw.Container(height: thickness, color: theme.rule);

  pw.Widget _sectionHeading(String title, {String? note}) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 16),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(width: 3, height: 14, color: theme.accent),
          pw.SizedBox(width: 8),
          pw.Text(title, style: style.h1),
          if (note != null) ...[
            pw.SizedBox(width: 8),
            pw.Text(note, style: style.caption),
          ],
        ],
      ),
      pw.SizedBox(height: 6),
      _rule(),
      pw.SizedBox(height: 10),
    ],
  );

  pw.Widget _empty(String what) => pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: theme.card,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Text('No $what in this period.', style: style.small),
  );

  // ------------------------------------------------------------------ cover

  pw.Page _cover() {
    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: _pageFormat,
        margin: const pw.EdgeInsets.all(_margin),
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: theme.page),
        ),
      ),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 26),
          pw.Row(
            children: [
              pw.Container(width: 26, height: 26, color: theme.accent),
              pw.SizedBox(width: 10),
              pw.Text('Flow-tracker', style: style.h1),
              pw.Spacer(),
              pw.Text('Report', style: style.caption),
            ],
          ),
          pw.SizedBox(height: 18),
          _rule(),
          pw.SizedBox(height: 60),
          pw.Text(options.type.label, style: style.title),
          pw.SizedBox(height: 10),
          pw.Container(width: 64, height: 3, color: theme.accent),
          pw.SizedBox(height: 22),
          pw.Text('Reporting period', style: style.caption),
          pw.SizedBox(height: 3),
          pw.Text(_period(), style: style.body),
          pw.SizedBox(height: 12),
          pw.Text('Generated', style: style.caption),
          pw.SizedBox(height: 3),
          pw.Text(
            '${_d(generatedAt)} · ${_two(generatedAt.hour)}:${_two(generatedAt.minute)}',
            style: style.body,
          ),
          pw.SizedBox(height: 12),
          pw.Text('Theme', style: style.caption),
          pw.SizedBox(height: 3),
          pw.Text(options.theme.label, style: style.body),
          pw.Spacer(),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: theme.card,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              children: [
                _coverStat('${data.totalHabits}', 'habits'),
                _coverStat(_percent(data.percent), 'completion'),
                _coverStat('${data.bestStreak}', 'best streak'),
                _coverStat('${data.trackedDays}', 'days tracked'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _rule(),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text('Created by Umaiz Sufiyan', style: style.small),
              pw.Spacer(),
              pw.Text('Flow-tracker $version', style: style.caption),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _coverStat(String value, String label) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value, style: style.accentStat),
        pw.SizedBox(height: 2),
        pw.Text(label, style: style.caption),
      ],
    ),
  );

  // ------------------------------------------------------------------- body

  pw.MultiPage _body() {
    final blocks = <pw.Widget>[];

    if (data.isEmpty) {
      blocks.add(_sectionHeading('Nothing to report'));
      blocks.add(
        _empty('habits, to-dos or focus sessions'),
      );
    }

    for (final section in PdfSection.values) {
      if (!options.sections.contains(section)) continue;
      switch (section) {
        case PdfSection.overview:
          blocks.addAll(_overview());
        case PdfSection.charts:
          blocks.addAll(_charts());
        case PdfSection.habitStats:
          blocks.addAll(_habitStats());
        case PdfSection.habitDetails:
          blocks.addAll(_habitDetails());
        case PdfSection.completionHistory:
          blocks.addAll(_completionHistory());
        case PdfSection.heatmap:
          blocks.addAll(_heatmap());
        case PdfSection.streaks:
          blocks.addAll(_streaks());
        case PdfSection.todos:
          blocks.addAll(_todos());
        case PdfSection.focus:
          blocks.addAll(_focus());
        case PdfSection.notes:
          blocks.addAll(_notes());
      }
    }

    return pw.MultiPage(
      pageTheme: _pageTheme,
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 10, height: 10, color: theme.accent),
              pw.SizedBox(width: 6),
              pw.Text(
                'Flow-tracker · ${options.type.label}',
                style: style.caption,
              ),
              pw.Spacer(),
              pw.Text(_period(), style: style.caption),
            ],
          ),
          pw.SizedBox(height: 6),
          _rule(thickness: 0.4),
        ],
      ),
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _rule(thickness: 0.4),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text('Flow-tracker · ${_period()}', style: style.caption),
              pw.Spacer(),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: style.caption,
              ),
            ],
          ),
        ],
      ),
      build: (context) => blocks,
    );
  }

  // --------------------------------------------------------------- sections

  List<pw.Widget> _overview() {
    final cards = <pw.Widget>[
      _statCard('${data.totalHabits}', 'Habits in period'),
      _statCard('${data.completedTotal}', 'Completed entries'),
      _statCard(_percent(data.percent), 'Completion rate'),
      _statCard('${data.currentStreak}', 'Best current streak'),
      _statCard('${data.bestStreak}', 'Best streak'),
      _statCard('${data.trackedDays}/${data.days}', 'Days tracked'),
      _statCard(_percent(data.consistency), 'Consistency'),
      if (data.focus.isNotEmpty)
        _statCard('${data.focusMinutes} min', 'Focus time'),
      if (data.todos.isNotEmpty)
        _statCard('${data.todosDone}/${data.todosTotal}', 'To-dos done'),
    ];
    final rows = <pw.Widget>[];
    for (var i = 0; i < cards.length; i += 3) {
      final slice = cards.sublist(i, math.min(i + 3, cards.length));
      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < 3; j++) ...[
              if (j > 0) pw.SizedBox(width: 8),
              if (j < slice.length)
                pw.Expanded(child: slice[j])
              else
                pw.Expanded(child: pw.SizedBox()),
            ],
          ],
        ),
      );
      rows.add(pw.SizedBox(height: 8));
    }
    return [_sectionHeading('Executive summary'), ...rows];
  }

  pw.Widget _statCard(String value, String label) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: pw.BoxDecoration(
      color: theme.card,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: theme.rule, width: 0.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value, style: style.stat),
        pw.SizedBox(height: 2),
        pw.Text(label, style: style.caption),
      ],
    ),
  );

  List<pw.Widget> _charts() {
    final out = <pw.Widget>[_sectionHeading('Activity')];
    if (data.dailyCounts.isEmpty) {
      out.add(_empty('logged activity'));
      return out;
    }
    out.add(pw.Text('Completions per day', style: style.h2));
    out.add(pw.SizedBox(height: 6));
    out.add(_barChart());
    out.add(pw.SizedBox(height: 14));
    if (data.categoryTotals.isNotEmpty) {
      out.add(pw.Text('Completions by category', style: style.h2));
      out.add(pw.SizedBox(height: 6));
      out.add(_categoryBars());
    }
    return out;
  }

  /// A vector bar chart drawn from the real daily counts. Container maths keeps
  /// it crisp at print resolution and avoids raster images entirely.
  pw.Widget _barChart() {
    final days = <String>[];
    var cursor = data.from;
    while (!cursor.isAfter(data.to) && days.length < 62) {
      days.add(_d(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    if (days.isEmpty) return pw.SizedBox();
    final peak = math.max(1, data.peakDay);
    const chartHeight = 86.0;
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(8, 10, 8, 6),
      decoration: pw.BoxDecoration(
        color: theme.card,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: theme.rule, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            height: chartHeight,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (final day in days) ...[
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 0.8),
                      child: pw.Container(
                        height: math.max(
                          1.5,
                          chartHeight *
                              ((data.dailyCounts[day] ?? 0) / peak).clamp(
                                0.0,
                                1.0,
                              ),
                        ),
                        decoration: pw.BoxDecoration(
                          color: (data.dailyCounts[day] ?? 0) == 0
                              ? theme.rule
                              : theme.accent,
                          borderRadius: pw.BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text(days.first, style: style.caption),
              pw.Spacer(),
              pw.Text('peak $peak/day', style: style.caption),
              pw.Spacer(),
              pw.Text(days.last, style: style.caption),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _categoryBars() {
    final entries = data.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peak = entries.first.value;
    return pw.Column(
      children: [
        for (final entry in entries.take(8))
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 96,
                  child: pw.Text(entry.key, style: style.small),
                ),
                pw.Expanded(
                  child: pw.Container(
                    height: 9,
                    alignment: pw.Alignment.centerLeft,
                    decoration: pw.BoxDecoration(
                      color: theme.accentSoft,
                      borderRadius: pw.BorderRadius.circular(4.5),
                    ),
                    child: pw.Container(
                      width: 168 * (entry.value / peak).clamp(0.02, 1.0),
                      height: 9,
                      decoration: pw.BoxDecoration(
                        color: theme.accent,
                        borderRadius: pw.BorderRadius.circular(4.5),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 24,
                  child: pw.Text(
                    '${entry.value}',
                    style: style.caption,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<pw.Widget> _habitStats() {
    final out = <pw.Widget>[
      _sectionHeading('Habit statistics', note: '${data.habits.length} habits'),
    ];
    if (data.habits.isEmpty) {
      out.add(_empty('habits'));
      return out;
    }
    out.add(
      pw.TableHelper.fromTextArray(
        headers: const [
          'Habit',
          'Category',
          'Scheduled',
          'Done',
          '%',
          'Streak',
          'Best',
        ],
        data: [
          for (final habit in data.habits)
            [
              habit.name,
              habit.category,
              '${habit.scheduled}',
              '${habit.completed}',
              _percent(habit.percent),
              '${habit.currentStreak}',
              '${habit.bestStreak}',
            ],
        ],
        headerStyle: pw.TextStyle(
          font: style.h2.font,
          fontSize: 8.5,
          color: theme.ink,
        ),
        headerDecoration: pw.BoxDecoration(color: theme.accentSoft),
        cellStyle: style.small,
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
          4: pw.Alignment.center,
          5: pw.Alignment.center,
          6: pw.Alignment.center,
        },
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: theme.rule, width: 0.4),
        ),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
    );
    return out;
  }

  List<pw.Widget> _habitDetails() {
    final out = <pw.Widget>[
      _sectionHeading('Individual habits'),
    ];
    if (data.habits.isEmpty) {
      out.add(_empty('habits'));
      return out;
    }
    for (final habit in data.habits) {
      out.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 9),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(habit.name, style: style.h2)),
                  pw.Text(_percent(habit.percent), style: style.small),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Container(
                height: 7,
                alignment: pw.Alignment.centerLeft,
                decoration: pw.BoxDecoration(
                  color: theme.accentSoft,
                  borderRadius: pw.BorderRadius.circular(3.5),
                ),
                child: pw.Container(
                  width: 420 * habit.percent.clamp(0.0, 1.0),
                  height: 7,
                  decoration: pw.BoxDecoration(
                    color: theme.accent,
                    borderRadius: pw.BorderRadius.circular(3.5),
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '${habit.completed} of ${habit.scheduled} scheduled days · '
                '${habit.category} · current streak ${habit.currentStreak}',
                style: style.caption,
              ),
            ],
          ),
        ),
      );
    }
    return out;
  }

  List<pw.Widget> _completionHistory() {
    final rows = data.history();
    final out = <pw.Widget>[
      _sectionHeading('Completion history', note: '${rows.length} entries'),
    ];
    if (rows.isEmpty) {
      out.add(_empty('completions'));
      return out;
    }
    out.add(
      pw.TableHelper.fromTextArray(
        headers: const ['Date', 'Habit', 'Count'],
        data: [
          for (final row in rows)
            [row.day, row.habit, row.count == 1 ? '1' : row.count.toString()],
        ],
        headerStyle: pw.TextStyle(
          font: style.h2.font,
          fontSize: 8.5,
          color: theme.ink,
        ),
        headerDecoration: pw.BoxDecoration(color: theme.accentSoft),
        cellStyle: style.small,
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.center,
        },
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: theme.rule, width: 0.4),
        ),
        cellPadding: const pw.EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3.5,
        ),
      ),
    );
    return out;
  }

  List<pw.Widget> _heatmap() {
    final out = <pw.Widget>[_sectionHeading('Activity heatmap')];
    if (data.dailyCounts.isEmpty) {
      out.add(_empty('activity'));
      return out;
    }
    final peak = math.max(1, data.peakDay);
    // last 16 weeks, ending on the report end date
    const weeks = 16;
    final end = data.to;
    final start = end.subtract(Duration(days: weeks * 7 - 1));
    final columns = <pw.Widget>[];
    for (var week = 0; week < weeks; week++) {
      final days = <pw.Widget>[];
      for (var d = 0; d < 7; d++) {
        final day = start.add(Duration(days: week * 7 + d));
        final key = _d(day);
        final count = data.dailyCounts[key] ?? 0;
        final inside = !day.isBefore(data.from) && !day.isAfter(data.to);
        final intensity = (count / peak).clamp(0.0, 1.0);
        final colour = !inside
            ? theme.card
            : count == 0
            ? theme.rule
            : theme.accent.shade(1 - 0.62 * (1 - intensity));
        days.add(
          pw.Container(
            width: 11,
            height: 11,
            margin: const pw.EdgeInsets.all(1),
            decoration: pw.BoxDecoration(
              color: colour,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
        );
      }
      columns.add(pw.Column(children: days));
    }
    out.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: theme.card,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: theme.rule, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(children: columns),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Text('${_d(start)} — ${_d(end)}', style: style.caption),
                pw.Spacer(),
                pw.Text('darker = more completions', style: style.caption),
              ],
            ),
          ],
        ),
      ),
    );
    return out;
  }

  List<pw.Widget> _streaks() {
    final out = <pw.Widget>[_sectionHeading('Streaks')];
    if (data.habits.isEmpty) {
      out.add(_empty('habits'));
      return out;
    }
    final sorted = [...data.habits]
      ..sort((a, b) => b.bestStreak.compareTo(a.bestStreak));
    out.add(
      pw.TableHelper.fromTextArray(
        headers: const ['Habit', 'Current', 'Best'],
        data: [
          for (final habit in sorted)
            [habit.name, '${habit.currentStreak}', '${habit.bestStreak}'],
        ],
        headerStyle: pw.TextStyle(
          font: style.h2.font,
          fontSize: 8.5,
          color: theme.ink,
        ),
        headerDecoration: pw.BoxDecoration(color: theme.accentSoft),
        cellStyle: style.small,
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
        },
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: theme.rule, width: 0.4),
        ),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
    );
    return out;
  }

  List<pw.Widget> _todos() {
    final out = <pw.Widget>[
      _sectionHeading(
        'To-dos',
        note: '${data.todosDone} of ${data.todosTotal} done',
      ),
    ];
    if (data.todos.isEmpty) {
      out.add(_empty('to-dos'));
      return out;
    }
    out.add(
      pw.TableHelper.fromTextArray(
        headers: const ['Task', 'Date', 'Status'],
        data: [
          for (final todo in data.todos.take(200))
            [todo.text, todo.date, todo.done ? 'Done' : 'Open'],
        ],
        headerStyle: pw.TextStyle(
          font: style.h2.font,
          fontSize: 8.5,
          color: theme.ink,
        ),
        headerDecoration: pw.BoxDecoration(color: theme.accentSoft),
        cellStyle: style.small,
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.center,
        },
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: theme.rule, width: 0.4),
        ),
        cellPadding: const pw.EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3.5,
        ),
      ),
    );
    return out;
  }

  List<pw.Widget> _focus() {
    final out = <pw.Widget>[
      _sectionHeading(
        'Focus sessions',
        note: '${data.focusSessions} sessions · ${data.focusMinutes} min',
      ),
    ];
    if (data.focus.isEmpty) {
      out.add(_empty('focus sessions'));
      return out;
    }
    out.add(
      pw.TableHelper.fromTextArray(
        headers: const ['Date', 'Minutes', 'Target', 'Status'],
        data: [
          for (final session in data.focus.take(200))
            [
              _d(session.startedAt),
              '${(session.seconds / 60).round()}',
              '${session.targetMinutes}',
              session.completed ? 'Completed' : 'Ended early',
            ],
        ],
        headerStyle: pw.TextStyle(
          font: style.h2.font,
          fontSize: 8.5,
          color: theme.ink,
        ),
        headerDecoration: pw.BoxDecoration(color: theme.accentSoft),
        cellStyle: style.small,
        cellAlignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
        },
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: theme.rule, width: 0.4),
        ),
        cellPadding: const pw.EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3.5,
        ),
      ),
    );
    return out;
  }

  List<pw.Widget> _notes() {
    final out = <pw.Widget>[_sectionHeading('Notes')];
    if (data.notes.isEmpty) {
      out.add(_empty('notes'));
      return out;
    }
    for (final note in data.notes.take(60)) {
      out.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: pw.Container(
            padding: const pw.EdgeInsets.all(9),
            decoration: pw.BoxDecoration(
              color: theme.card,
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(note.date, style: style.caption),
                pw.SizedBox(height: 2),
                pw.Text(note.text, style: style.small),
              ],
            ),
          ),
        ),
      );
    }
    return out;
  }
}
