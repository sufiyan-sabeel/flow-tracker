import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flow_tracker/services/pdf/pdf_export_options.dart';
import 'package:flow_tracker/services/pdf/pdf_report_data.dart';
import 'package:flow_tracker/services/pdf/pdf_theme.dart';

/// Turns aggregated [ReportData] into a real PDF document.
///
/// Pure by design: no storage, no plugins, no network. The caller supplies the
/// data, the fonts and the logo, which keeps the output testable and guarantees
/// the document can be produced offline.
class PdfReportBuilder {
  PdfReportBuilder({
    required this.options,
    required this.data,
    required this.style,
    required this.generatedAt,
    required this.version,
    this.logo,
  });

  final PdfExportOptions options;
  final ReportData data;
  final PdfStyle style;
  final DateTime generatedAt;
  final String version;
  final pw.ImageProvider? logo;

  static const _pageFormat = PdfPageFormat.a4;
  static const _margin = 44.0;

  /// Rows per table block. Tables are emitted in blocks so the header repeats on
  /// every page instead of a headerless continuation.
  static const _rowsPerBlock = 20;

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
    margin: const pw.EdgeInsets.fromLTRB(_margin, 52, _margin, 50),
    buildBackground: (context) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Container(color: theme.page),
    ),
  );

  pw.Widget _rule({double thickness = 0.6}) =>
      pw.Container(height: thickness, color: theme.rule);

  pw.Widget _mark(double size) => logo == null
      ? pw.Container(width: size, height: size, color: theme.accent)
      : pw.SizedBox(
          width: size,
          height: size,
          child: pw.Image(logo!, fit: pw.BoxFit.contain),
        );

  pw.Widget _sectionHeading(String title, {String? note}) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 26),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(width: 3, height: 16, color: theme.accent),
          pw.SizedBox(width: 9),
          pw.Text(title, style: style.h1),
          if (note != null) ...[
            pw.SizedBox(width: 9),
            pw.Text(note, style: style.caption),
          ],
        ],
      ),
      pw.SizedBox(height: 8),
      _rule(),
      pw.SizedBox(height: 12),
    ],
  );

  pw.Widget _empty(String what) => pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: theme.card,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Text(
      'No $what recorded in this period. '
      'Nothing is estimated or filled in.',
      style: style.small,
    ),
  );

  /// A table whose header repeats on every page: rows are emitted in blocks,
  /// each with its own header, and alternate rows are tinted.
  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, pw.AlignmentGeometry> alignments,
    String? continuedNote,
  }) {
    if (rows.isEmpty) return _empty('records');
    final blocks = <pw.Widget>[];
    for (var start = 0; start < rows.length; start += _rowsPerBlock) {
      final slice = rows.sublist(
        start,
        math.min(start + _rowsPerBlock, rows.length),
      );
      if (start > 0) {
        blocks.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
            child: pw.Text(
              continuedNote ?? 'continued',
              style: style.caption,
            ),
          ),
        );
      }
      blocks.add(
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: slice,
          headerStyle: pw.TextStyle(
            font: style.h2.font,
            fontSize: 8.5,
            color: theme.ink,
          ),
          headerDecoration: pw.BoxDecoration(color: theme.accentSoft),
          cellStyle: style.table,
          oddCellStyle: pw.TextStyle(
            font: style.table.font,
            fontSize: style.table.fontSize,
            color: style.table.color,
            background: pw.BoxDecoration(color: theme.card),
          ),
          cellAlignments: alignments,
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: theme.rule, width: 0.4),
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 7,
          ),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: blocks,
    );
  }

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
          // ---- brand row
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _mark(30),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Flow-tracker', style: style.wordmark),
                  pw.Text('Habit tracking, reported', style: style.caption),
                ],
              ),
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: theme.accentSoft,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  options.type.category,
                  style: pw.TextStyle(
                    font: style.h2.font,
                    fontSize: 7.5,
                    color: theme.accent,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          _rule(),
          pw.SizedBox(height: 54),

          // ---- title block
          pw.Text(options.type.label, style: style.coverTitle),
          pw.SizedBox(height: 12),
          pw.Container(width: 72, height: 3, color: theme.accent),
          pw.SizedBox(height: 16),
          pw.SizedBox(
            width: 360,
            child: pw.Text(options.type.blurb, style: style.lead),
          ),
          pw.SizedBox(height: 30),

          // ---- meta
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _meta('Reporting period', _period()),
              pw.SizedBox(width: 28),
              _meta(
                'Generated',
                '${_d(generatedAt)} · ${_two(generatedAt.hour)}:${_two(generatedAt.minute)}',
              ),
              pw.SizedBox(width: 28),
              _meta('Design', options.theme.label),
            ],
          ),
          pw.Spacer(),

          // ---- headline numbers
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: pw.BoxDecoration(
              color: theme.card,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: theme.rule, width: 0.6),
            ),
            child: pw.Row(
              children: [
                _coverStat('${data.totalHabits}', 'habits'),
                _coverStat(_percent(data.percent), 'completion'),
                _coverStat('${data.currentStreak}', 'current streak'),
                _coverStat('${data.bestStreak}', 'best streak'),
              ],
            ),
          ),
          pw.SizedBox(height: 26),

          // ---- what the reader is about to see
          pw.Text('Inside this report', style: style.h2),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final section in PdfSection.values)
                if (options.sections.contains(section))
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: theme.rule, width: 0.6),
                    ),
                    child: pw.Text(section.label, style: style.caption),
                  ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text('How these numbers are calculated', style: style.h2),
          pw.SizedBox(height: 6),
          pw.SizedBox(
            width: 380,
            child: pw.Text(
              'Scheduled days are the days each habit was due, counted from the '
              'day it was created. A habit made last week is not marked down for '
              'the weeks before it existed. Completions logged on a day a habit '
              'was not due are reported as entries, not as scheduled wins. '
              'Nothing here is estimated: an empty period says so.',
              style: style.caption,
            ),
          ),
          pw.SizedBox(height: 22),

          // ---- footer
          _rule(),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text('Created by Umaiz Sufiyan', style: style.small),
              pw.Spacer(),
              pw.Text('Flow-tracker $version', style: style.caption),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Generated on this device from local data · no account, no upload',
            style: style.caption,
          ),
        ],
      ),
    );
  }

  pw.Widget _meta(String label, String value) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(), style: style.metaLabel),
        pw.SizedBox(height: 3),
        pw.Text(value, style: style.body),
      ],
    ),
  );

  pw.Widget _coverStat(String value, String label) => pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value, style: style.accentStat),
        pw.SizedBox(height: 3),
        pw.Text(label, style: style.caption),
      ],
    ),
  );

  // ------------------------------------------------------------------- body

  pw.MultiPage _body() {
    final blocks = <pw.Widget>[];

    if (data.isEmpty) {
      blocks.add(_sectionHeading('Nothing to report'));
      blocks.add(_empty('habits, to-dos or focus sessions'));
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
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _mark(11),
              pw.SizedBox(width: 6),
              pw.Text(
                'Flow-tracker · ${options.type.label}',
                style: style.caption,
              ),
              pw.Spacer(),
              pw.Text(_period(), style: style.caption),
            ],
          ),
          pw.SizedBox(height: 7),
          _rule(thickness: 0.4),
        ],
      ),
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _rule(thickness: 0.4),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text('Flow-tracker · ${_period()}', style: style.footer),
              pw.Spacer(),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: style.footer,
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
      _statCard('${data.entries}', 'Completions logged'),
      _statCard(_percent(data.percent), 'Completion rate'),
      _statCard(
        '${data.completedTotal}/${data.scheduledTotal}',
        'Scheduled days done',
      ),
      _statCard('${data.currentStreak}', 'Current streak'),
      _statCard('${data.bestStreak}', 'Best streak'),
      _statCard('${data.trackedDays} of ${data.days}', 'Days tracked'),
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
              if (j > 0) pw.SizedBox(width: 9),
              pw.Expanded(
                child: j < slice.length ? slice[j] : pw.SizedBox(),
              ),
            ],
          ],
        ),
      );
      rows.add(pw.SizedBox(height: 9));
    }
    return [
      _sectionHeading(
        'Executive summary',
        note: '${_d(data.from)} → ${_d(data.to)}',
      ),
      ...rows,
      pw.SizedBox(height: 4),
      pw.Text(
        'Completion rate counts scheduled days only, from the day each habit '
        'was created. Days before a habit existed are not counted as missed.',
        style: style.caption,
      ),
    ];
  }

  pw.Widget _statCard(String value, String label) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: pw.BoxDecoration(
      color: theme.card,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: theme.rule, width: 0.6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value, style: style.stat),
        pw.SizedBox(height: 3),
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
    out.add(pw.SizedBox(height: 8));
    out.add(_barChart());
    out.add(pw.SizedBox(height: 18));
    if (data.categoryTotals.isNotEmpty) {
      out.add(pw.Text('Completions by category', style: style.h2));
      out.add(pw.SizedBox(height: 8));
      out.add(_categoryBars());
      out.add(pw.SizedBox(height: 18));
    }
    out.add(pw.Text('Habit completion', style: style.h2));
    out.add(pw.SizedBox(height: 8));
    out.add(_habitBars());
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
    const chartHeight = 92.0;
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 12, 10, 8),
      decoration: pw.BoxDecoration(
        color: theme.card,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: theme.rule, width: 0.6),
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
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text(days.first, style: style.caption),
              pw.Spacer(),
              pw.Text('peak $peak per day', style: style.caption),
              pw.Spacer(),
              pw.Text(days.last, style: style.caption),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _barRow(String label, double factor, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      children: [
        pw.SizedBox(width: 104, child: pw.Text(label, style: style.small)),
        pw.Expanded(
          child: pw.Container(
            height: 9,
            alignment: pw.Alignment.centerLeft,
            decoration: pw.BoxDecoration(
              color: theme.accentSoft,
              borderRadius: pw.BorderRadius.circular(4.5),
            ),
            child: pw.Container(
              width: 168 * factor.clamp(0.02, 1.0),
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
          width: 30,
          child: pw.Text(
            value,
            style: style.caption,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );

  pw.Widget _categoryBars() {
    final entries = data.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peak = entries.first.value;
    return pw.Column(
      children: [
        for (final entry in entries.take(8))
          _barRow(entry.key, entry.value / peak, '${entry.value}'),
      ],
    );
  }

  pw.Widget _habitBars() {
    if (data.habits.isEmpty) return _empty('habits');
    return pw.Column(
      children: [
        for (final habit in data.habits.take(8))
          _barRow(habit.name, habit.percent, _percent(habit.percent)),
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
      _table(
        headers: const [
          'Habit',
          'Category',
          'Scheduled',
          'Done',
          '%',
          'Current',
          'Best',
        ],
        rows: [
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
        alignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
          4: pw.Alignment.center,
          5: pw.Alignment.center,
          6: pw.Alignment.center,
        },
      ),
    );
    return out;
  }

  List<pw.Widget> _habitDetails() {
    final out = <pw.Widget>[_sectionHeading('Individual habits')];
    if (data.habits.isEmpty) {
      out.add(_empty('habits'));
      return out;
    }
    for (final habit in data.habits) {
      out.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 11),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(habit.name, style: style.h2)),
                  pw.Text(
                    '${_percent(habit.percent)} · ${habit.completed}/'
                    '${habit.scheduled} days',
                    style: style.small,
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
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
              pw.SizedBox(height: 4),
              pw.Text(
                '${habit.category} · tracked from ${_d(habit.firstDay)} · '
                'current streak ${habit.currentStreak}, best ${habit.bestStreak}',
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
      _table(
        headers: const ['Date', 'Habit', 'Count'],
        rows: [
          for (final row in rows)
            [row.day, row.habit, row.count == 1 ? '1' : row.count.toString()],
        ],
        alignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.center,
        },
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
    const weeks = 16;
    final end = data.to;
    final start = end.subtract(const Duration(days: weeks * 7 - 1));
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
            ? theme.page
            : count == 0
            ? theme.rule
            : theme.accent.shade(1 - 0.62 * (1 - intensity));
        days.add(
          pw.Container(
            width: 12,
            height: 12,
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
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: theme.card,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: theme.rule, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(children: columns),
            pw.SizedBox(height: 8),
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
      _table(
        headers: const ['Habit', 'Current streak', 'Best streak'],
        rows: [
          for (final habit in sorted)
            [habit.name, '${habit.currentStreak}', '${habit.bestStreak}'],
        ],
        alignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
        },
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
      _table(
        headers: const ['Task', 'Date', 'Status'],
        rows: [
          for (final todo in data.todos.take(200))
            [todo.text, todo.date, todo.done ? 'Done' : 'Open'],
        ],
        alignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.center,
        },
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
      _table(
        headers: const ['Date', 'Minutes', 'Target', 'Status'],
        rows: [
          for (final session in data.focus.take(200))
            [
              _d(session.startedAt),
              '${(session.seconds / 60).round()}',
              '${session.targetMinutes}',
              session.completed ? 'Completed' : 'Ended early',
            ],
        ],
        alignments: {
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.center,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
        },
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
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: theme.card,
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(note.date, style: style.caption),
                pw.SizedBox(height: 3),
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
