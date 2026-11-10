import 'dart:math' as math;

import 'package:flow_tracker/core/database/local_store.dart';
import 'package:flow_tracker/core/extensions/date_extensions.dart';
import 'package:flow_tracker/features/focus/data/focus_session.dart';
import 'package:flow_tracker/features/habits/data/category.dart';
import 'package:flow_tracker/features/habits/data/habit_note.dart';
import 'package:flow_tracker/features/todos/data/todo.dart';

/// One habit's numbers inside the reported window.
class HabitLine {
  const HabitLine({
    required this.name,
    required this.category,
    required this.scheduled,
    required this.completed,
    required this.entries,
    required this.currentStreak,
    required this.bestStreak,
    required this.firstDay,
  });

  final String name;
  final String category;

  /// Days this habit was scheduled *and* the habit already existed.
  final int scheduled;

  /// Scheduled days that were actually completed.
  final int completed;

  /// Completion records logged, including any on unscheduled days.
  final int entries;
  final int currentStreak;
  final int bestStreak;

  /// First day this habit counted towards the report (creation, or window start).
  final DateTime firstDay;

  double get percent => scheduled == 0 ? 0 : completed / scheduled;
}

/// One row of the completion history table.
class HistoryRow {
  const HistoryRow({
    required this.day,
    required this.habit,
    required this.count,
  });

  final String day;
  final String habit;
  final double count;
}

/// Everything a report needs, calculated once from the local database.
///
/// Two rules keep the numbers honest, and both were wrong in the first version:
///
/// 1. A habit only counts from the day it was created. A habit made last week is
///    not "missing" for the previous three weeks.
/// 2. The "all history" range starts at the earliest real record, not at a
///    hard-coded year. Otherwise the denominator becomes thousands of days and
///    every completion rate collapses to 0%.
class ReportData {
  ReportData({
    required this.from,
    required this.to,
    required this.habits,
    required this.todos,
    required this.focus,
    required this.notes,
    required this.dailyCounts,
    required this.categoryTotals,
    required this.entries,
    required this.historyStart,
  });

  final DateTime from;
  final DateTime to;
  final List<HabitLine> habits;
  final List<Todo> todos;
  final List<FocusSession> focus;
  final List<HabitNote> notes;

  /// dayKey → scheduled completions logged that day, inside the window.
  final Map<String, int> dailyCounts;

  /// Category name → completions, inside the window.
  final Map<String, int> categoryTotals;

  /// Every completion record in the window, including unscheduled days.
  final int entries;

  /// The earliest record in the whole database; the floor for "all history".
  final DateTime? historyStart;

  int get days => to.difference(from).inDays + 1;

  int get totalHabits => habits.length;

  int get scheduledTotal =>
      habits.fold(0, (sum, habit) => sum + habit.scheduled);

  int get completedTotal =>
      habits.fold(0, (sum, habit) => sum + habit.completed);

  double get percent =>
      scheduledTotal == 0 ? 0 : completedTotal / scheduledTotal;

  int get bestStreak =>
      habits.isEmpty ? 0 : habits.map((h) => h.bestStreak).reduce(math.max);

  int get currentStreak =>
      habits.isEmpty ? 0 : habits.map((h) => h.currentStreak).reduce(math.max);

  int get trackedDays => dailyCounts.keys.length;

  double get consistency => days == 0 ? 0 : trackedDays / days;

  int get todosTotal => todos.length;

  int get todosDone => todos.where((todo) => todo.done).length;

  int get focusMinutes =>
      (focus.fold(0, (sum, s) => sum + s.seconds) / 60).round();

  int get focusSessions => focus.length;

  bool get isEmpty =>
      habits.isEmpty && todos.isEmpty && focus.isEmpty && notes.isEmpty;

  int get peakDay =>
      dailyCounts.isEmpty ? 0 : dailyCounts.values.reduce(math.max);

  /// Reads the real database and aggregates [from]..[to] (inclusive).
  static ReportData load({
    required DateTime from,
    required DateTime to,
    DateTime? today,
  }) {
    final store = LocalStore.readHabits();
    final todos = LocalStore.readTodos();
    final focus = LocalStore.readFocusSessions();
    final notes = LocalStore.readNotes();
    final categories = <String, Category>{
      for (final category in LocalStore.readCategories()) category.id: category,
    };

    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    final todayDay = day(today ?? DateTime.now());
    var start = day(from);
    final end = day(to).isAfter(todayDay) ? todayDay : day(to);

    // The earliest thing that actually exists, so "all history" cannot start
    // before the user's first record.
    DateTime? earliest;
    void consider(DateTime? candidate) {
      if (candidate == null) return;
      final d = day(candidate);
      if (d.isAfter(todayDay)) return;
      if (earliest == null || d.isBefore(earliest!)) earliest = d;
    }

    for (final habit in store.values) {
      consider(habit.createdAt);
      for (final key in habit.completions.keys) {
        consider(DateTime.tryParse(key));
      }
    }
    for (final todo in todos) {
      consider(DateTime.tryParse(todo.date));
    }
    for (final session in focus) {
      consider(session.startedAt);
    }

    if (earliest != null && start.isBefore(earliest!)) start = earliest!;
    if (start.isAfter(end)) start = end;

    final lines = <HabitLine>[];
    final daily = <String, int>{};
    final byCategory = <String, int>{};
    var entries = 0;

    for (final habit in store.values) {
      final created = day(habit.createdAt);
      // a habit cannot be scheduled before it existed
      var cursor = created.isAfter(start) ? created : start;
      final firstDay = cursor;
      var scheduled = 0;
      var completed = 0;
      var habitEntries = 0;

      while (!cursor.isAfter(end)) {
        final key = cursor.dayKey;
        final record = habit.completions[key];
        if (record != null) {
          habitEntries++;
          entries++;
        }
        if (habit.isScheduledOn(cursor)) {
          scheduled++;
          if (record != null) {
            completed++;
            daily.update(key, (n) => n + 1, ifAbsent: () => 1);
            final name = habit.category.isEmpty
                ? 'Uncategorised'
                : categories[habit.category]?.name ?? 'Uncategorised';
            byCategory.update(name, (n) => n + 1, ifAbsent: () => 1);
          }
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      if (scheduled == 0 && habitEntries == 0) continue;
      lines.add(
        HabitLine(
          name: habit.name,
          category: habit.category.isEmpty
              ? '—'
              : categories[habit.category]?.name ?? '—',
          scheduled: scheduled,
          completed: completed,
          entries: habitEntries,
          currentStreak: habit.currentStreak,
          bestStreak: habit.longestStreak,
          firstDay: firstDay,
        ),
      );
    }

    lines.sort((a, b) => b.percent.compareTo(a.percent));

    final todosInRange = todos.where((todo) {
      final parsed = DateTime.tryParse(todo.date);
      if (parsed == null) return false;
      final d = day(parsed);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final focusInRange = focus.where((session) {
      final d = day(session.startedAt);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final notesInRange = notes.where((note) {
      final parsed = DateTime.tryParse(note.date);
      if (parsed == null) return false;
      final d = day(parsed);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return ReportData(
      from: start,
      to: end,
      habits: lines,
      todos: todosInRange,
      focus: focusInRange,
      notes: notesInRange,
      dailyCounts: daily,
      categoryTotals: byCategory,
      entries: entries,
      historyStart: earliest,
    );
  }

  /// Flattened completion history, newest first, capped so a large export stays
  /// a sensible size.
  List<HistoryRow> history({int limit = 400}) {
    final rows = <HistoryRow>[];
    for (final habit in LocalStore.readHabits().values) {
      for (final entry in habit.completions.entries) {
        final parsed = DateTime.tryParse(entry.key);
        if (parsed == null) continue;
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (day.isBefore(from) || day.isAfter(to)) continue;
        rows.add(
          HistoryRow(
            day: entry.key,
            habit: habit.name,
            count: entry.value.count,
          ),
        );
      }
    }
    rows.sort((a, b) => b.day.compareTo(a.day));
    return rows.length > limit ? rows.sublist(0, limit) : rows;
  }
}
