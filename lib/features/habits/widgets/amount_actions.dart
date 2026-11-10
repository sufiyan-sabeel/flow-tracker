import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flow_tracker/core/extensions/date_extensions.dart';
import 'package:flow_tracker/core/i18n/l10n.dart';
import 'package:flow_tracker/core/widgets/number_keypad_dialog.dart';
import 'package:flow_tracker/features/focus/widgets/focus_setup_parts.dart';
import 'package:flow_tracker/features/habits/data/habit.dart';
import 'package:flow_tracker/features/habits/state/habits_controller.dart';
import 'package:flow_tracker/features/habits/widgets/unscheduled_day_dialog.dart';
import 'package:flow_tracker/features/settings/state/settings_controller.dart';
import 'package:flow_tracker/core/extensions/color_extensions.dart';

Future<void> addCustomAmount(BuildContext context, Habit habit) async {
  if (habit.kind != HabitKind.quantitative) return;

  final today = AppClock.now();
  if (!await confirmUnscheduledDay(context, habit: habit, date: today)) return;
  if (!context.mounted) return;

  final replacing = ValueNotifier(false);
  final focus =
      habit.isTimeAmount && context.read<SettingsController>().focusEnabled;
  final amount = await showNumberKeypadDialog(
    context,
    title: context.l10n.quant_add_title,
    value: 0,
    unit: habit.unitLabel,
    decimals: true,
    clock: habit.isTimeAmount,
    accent: habit.color.shownIn(context),
    replacing: replacing,
    extraLabel: focus ? context.l10n.focus_start : null,
    onExtra: () {
      if (!context.mounted) return;
      startFocusTimer(
        context,
        habit,
        FocusTimer(habit.focusMinutes, habit.focusBreakMinutes),
      );
    },
  );
  final replace = replacing.value;
  replacing.dispose();
  if (amount == null || !context.mounted) return;
  final controller = context.read<HabitsController>();
  if (replace) {
    await controller.setProgress(habit.id, today, amount);
  } else if (amount > 0) {
    await controller.addProgress(habit.id, today, amount);
  }
}
