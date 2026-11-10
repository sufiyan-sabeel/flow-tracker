import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flow_tracker/core/extensions/date_extensions.dart';
import 'package:flow_tracker/core/i18n/l10n.dart';
import 'package:flow_tracker/core/routing/app_navigator.dart';
import 'package:flow_tracker/core/utils/app_snackbar.dart';
import 'package:flow_tracker/core/widgets/app_confirm_dialog.dart';
import 'package:flow_tracker/features/focus/pages/focus_page.dart';
import 'package:flow_tracker/features/focus/state/focus_controller.dart';
import 'package:flow_tracker/features/habits/data/habit.dart';
import 'package:flow_tracker/features/habits/pages/habit_details_page.dart';
import 'package:flow_tracker/features/todos/data/todo.dart';

Future<bool> allowManualCheck(
  BuildContext context, {
  required Habit habit,
  required DateTime date,
}) async {
  if (habit.needsFocusSession && !habit.isTimeAmount && habit.isCompletedOn(date)) {
    final cleared = await showAppConfirmDialog(
      context,
      title: context.l10n.focus_only_clear_title,
      message: context.l10n.focus_only_clear_body(habit.name),
      confirmLabel: context.l10n.clear,
      extraLabel: context.l10n.focus_history,
      onExtra: () => AppNavigator.push(
        HabitDetailsPage(habitId: habit.id),
        fade: true,
      ),
      icon: LucideIcons.timer,
    );
    return cleared == true;
  }

  if (!habit.blocksManualCheck(date)) return true;

  if (date.dayKey != AppClock.now().dayKey) {
    AppSnackbar.error(context, context.l10n.focus_only_past(habit.name));
    return false;
  }

  final confirmed = await showAppConfirmDialog(
    context,
    title: context.l10n.focus_only_title,
    message: context.l10n.focus_only_body(habit.name),
    confirmLabel: context.l10n.focus_only_start,
    icon: LucideIcons.timer,
    danger: false,
  );
  if (confirmed != true || !context.mounted) return false;

  AppNavigator.push(
    context.read<FocusController>().isActive
        ? const FocusPage()
        : FocusPage(
            startHabitId: habit.id,
            startMinutes: habit.focusMinutes,
            breakMinutes: habit.focusBreakMinutes,
          ),
    name: FocusPage.routeName,
  );
  return false;
}

Future<bool> allowManualTodo(BuildContext context, Todo todo) async {
  if (!todo.blocksManualCheck) return true;
  final confirmed = await showAppConfirmDialog(
    context,
    title: context.l10n.focus_only_title,
    message: context.l10n.todo_focus_only_body(
      todo.title,
      '${todo.estimate}',
    ),
    confirmLabel: context.l10n.focus_only_start,
    icon: LucideIcons.timer,
    danger: false,
  );
  if (confirmed != true || !context.mounted) return false;

  AppNavigator.push(
    context.read<FocusController>().isActive
        ? const FocusPage()
        : FocusPage(
            startMinutes: todo.estimate,
            startLabel: todo.title,
            startTodoId: todo.id,
          ),
    name: FocusPage.routeName,
  );
  return false;
}
