import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flow_tracker/app/theme/app_palette.dart';
import 'package:flow_tracker/app/theme/app_theme.dart';
import 'package:flow_tracker/features/settings/state/settings_controller.dart';
import 'package:flow_tracker/core/database/local_store.dart';
import 'package:flow_tracker/core/utils/hex_color.dart';
import 'package:flow_tracker/features/settings/widgets/accent_sheet.dart';
import 'package:flow_tracker/l10n/app_localizations.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  /// Pumps a small app whose theme follows the settings controller, then opens
  /// the accent sheet from a button in the body.
  Future<SettingsController> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final controller = SettingsController();
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsController>.value(
        value: controller,
        child: Consumer<SettingsController>(
          builder: (_, settings, __) => MaterialApp(
            theme: AppTheme.light(settings.accentColor),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showAccentSheet(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Apply writes to storage before it notifies, so let the real write finish
  /// inside runAsync — otherwise the frame never sees the new theme.
  Future<void> tapApply(WidgetTester tester) async {
    final finder = find.text('Apply');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a preset previews at once but is only saved on apply', (
    tester,
  ) async {
    final controller = await openSheet(tester);
    expect(controller.accentColor, AppPalette.brand);

    await tester.tap(find.text('Ocean Blue'));
    await tester.pumpAndSettle();

    // The preview shows the candidate, the app has not changed yet.
    expect(find.text('#3B82F6'), findsWidgets);
    expect(controller.accentColor, AppPalette.brand);

    await tapApply(tester);
    expect(controller.accentColor, const Color(0xFF3B82F6));
    expect(find.text('Apply'), findsNothing);
  });

  testWidgets('cancel leaves the old colour alone', (tester) async {
    final controller = await openSheet(tester);

    await tester.tap(find.text('Rose Pink'));
    await tester.pumpAndSettle();
    await tapButton(tester, 'Cancel');

    expect(controller.accentColor, AppPalette.brand);
    expect(find.text('Apply'), findsNothing);
  });

  testWidgets('a bad hex is rejected with a message and changes nothing', (
    tester,
  ) async {
    final controller = await openSheet(tester);

    await tester.enterText(find.byType(TextField), 'not-a-colour');
    await tester.pumpAndSettle();

    expect(
      find.text('Use a hex colour such as #14B8A6'),
      findsOneWidget,
    );

    await tapApply(tester);
    expect(controller.accentColor, AppPalette.brand);
  });

  testWidgets('a valid hex is accepted', (tester) async {
    final controller = await openSheet(tester);

    await tester.enterText(find.byType(TextField), '#10B981');
    await tester.pumpAndSettle();
    expect(find.text('Use a hex colour such as #14B8A6'), findsNothing);

    await tapApply(tester);
    expect(controller.accentColor, const Color(0xFF10B981));
  });

  testWidgets('reset puts the default colour back', (tester) async {
    await tester.runAsync(() async {
      await LocalStore.writeSetting('accentColor', 0xFFEF4444);
    });

    final controller = await openSheet(tester);
    expect(controller.accentColor, const Color(0xFFEF4444));
    await tapButton(tester, 'Reset');
    expect(find.text(hexOf(AppPalette.brand)), findsWidgets);

    await tapApply(tester);
    expect(controller.accentColor, AppPalette.brand);
  });

  testWidgets('the whole app picks up the new accent after apply', (
    tester,
  ) async {
    final controller = await openSheet(tester);
    final before = Theme.of(
      tester.element(find.text('open')),
    ).colorScheme.primary;

    await tester.tap(find.text('Emerald Green'));
    await tester.pumpAndSettle();
    await tapApply(tester);

    final after = Theme.of(
      tester.element(find.text('open')),
    ).colorScheme.primary;
    expect(after, isNot(before));
    expect(after, AppTheme.adaptAccent(const Color(0xFF10B981), false));
    expect(controller.accentColor, const Color(0xFF10B981));
  });

  testWidgets('the custom picker is there for colours nobody preset', (
    tester,
  ) async {
    await openSheet(tester);
    expect(find.text('Custom'), findsOneWidget);
  });
}
