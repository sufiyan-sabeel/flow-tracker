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
    required this.currentStreak,
    required this.bestStreak,
  });

  final String name;
  final String category;
  final int scheduled;
  final int completed;
  final int currentStreak;
  final int bestStreak;

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

/// Everything a report needs, calculated from the local database once, so the
/// document builder never touches storage and never re-queries.
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
  });

  final DateTime from;
  final DateTime to;
  final List<HabitLine> habits;
  final List<Todo> todos;
  final List<FocusSession> focus;
  final List<HabitNote> notes;

  /// dayKey → completions logged that day, inside the window.
  final Map<String, int> dailyCounts;

  /// Category name → completions, inside the window.
  final Map<String, int> categoryTotals;

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

  /// The heaviest day in the window, used to scale charts.
  int get peakDay =>
      dailyCounts.isEmpty ? 0 : dailyCounts.values.reduce(math.max);

  /// Reads the real database and aggregates [from]..[to] (inclusive).
  ///
  /// Habits are counted only on days they are scheduled for, so a weekly habit
  /// is not marked down for the other six days.
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

    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final todayDay = today ?? DateTime.now();
    final now = DateTime(todayDay.year, todayDay.month, todayDay.day);

    final lines = <HabitLine>[];
    final daily = <String, int>{};
    final byCategory = <String, int>{};

    for (final habit in store.values) {
      var scheduled = 0;
      var completed = 0;
      var day = start;
      while (!day.isAfter(end)) {
        if (!day.isAfter(now) && habit.isScheduledOn(day)) {
          scheduled++;
          final done = habit.completions.containsKey(day.dayKey);
          if (done) {
            completed++;
            daily.update(day.dayKey, (n) => n + 1, ifAbsent: () => 1);
            final name = habit.category.isEmpty
                ? 'Uncategorised'
                : categories[habit.category]?.name ?? 'Uncategorised';
            byCategory.update(name, (n) => n + 1, ifAbsent: () => 1);
          }
        }
        day = day.add(const Duration(days: 1));
      }
      if (scheduled == 0 && completed == 0) continue;
      lines.add(
        HabitLine(
          name: habit.name,
          category: habit.category.isEmpty
              ? '—'
              : categories[habit.category]?.name ?? '—',
          scheduled: scheduled,
          completed: completed,
          currentStreak: habit.currentStreak,
          bestStreak: habit.longestStreak,
        ),
      );
    }

    lines.sort((a, b) => b.percent.compareTo(a.percent));

    final todosInRange = todos.where((todo) {
      final parsed = DateTime.tryParse(todo.date);
      if (parsed == null) return false;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final focusInRange = focus.where((session) {
      final day = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final notesInRange = notes.where((note) {
      final parsed = DateTime.tryParse(note.date);
      if (parsed == null) return false;
      final day = DateTime(parsed.year, parsed.month, parsed.day);
      return !day.isBefore(start) && !day.isAfter(end);
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
    );
  }

  /// Flattened completion history, newest first, capped so a large export stays
  /// a sensible size.
  List<HistoryRow> history({int limit = 400}) {
    final rows = <HistoryRow>[];
    final store = LocalStore.readHabits();
    for (final habit in store.values) {
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
