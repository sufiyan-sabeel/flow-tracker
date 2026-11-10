import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flow_tracker/app/liquid_nav_bar.dart';
import 'package:flow_tracker/app/theme/app_theme.dart';
import 'package:flow_tracker/core/database/local_store.dart';
import 'package:flow_tracker/features/settings/state/settings_controller.dart';

import 'support/app_harness.dart';

const _items = [
  LiquidNavItem(icon: Icons.home_outlined, label: 'Today'),
  LiquidNavItem(icon: Icons.checklist, label: 'To-Do'),
  LiquidNavItem(icon: Icons.calendar_today, label: 'Plan'),
  LiquidNavItem(icon: Icons.bar_chart, label: 'Stats'),
  LiquidNavItem(icon: Icons.settings_outlined, label: 'Settings'),
];

void main() {
  useEmptyStore();

  /// Pumps the dock alone with a controllable selection and compact flag.
  Future<ValueNotifier<bool>> pumpDock(
    WidgetTester tester, {
    int index = 0,
    Color? accent,
    Brightness brightness = Brightness.dark,
    bool amoled = false,
    Map<String, Object> settings = const {},
    double width = 393,
    double height = 851,
    ValueChanged<int>? onSelect,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      for (final entry in settings.entries) {
        await LocalStore.writeSetting(entry.key, entry.value);
      }
    });

    final compact = ValueNotifier(false);
    final controller = SettingsController();
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsController>.value(
        value: controller,
        child: MaterialApp(
          theme: brightness == Brightness.dark
              ? AppTheme.dark(accent, 0, null, amoled)
              : AppTheme.light(accent),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: LiquidGlassNavBar(
                items: _items,
                index: index,
                onSelect: onSelect ?? (_) {},
                compact: compact,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return compact;
  }

  testWidgets('every destination is there with a label for screen readers', (
    tester,
  ) async {
    await pumpDock(tester);

    expect(find.byType(LiquidGlassNavBar), findsOneWidget);
    for (final item in _items) {
      expect(
        find.bySemanticsLabel(item.label),
        findsOneWidget,
        reason: item.label,
      );
    }
    // only the selected destination carries a visible label
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Stats'), findsNothing);
  });

  testWidgets('tapping each destination reports its own index', (
    tester,
  ) async {
    final taps = <int>[];
    await pumpDock(tester, onSelect: taps.add);

    for (var i = 0; i < _items.length; i++) {
      await tester.tap(find.byIcon(_items[i].icon));
      await tester.pump();
    }
    expect(taps, [0, 1, 2, 3, 4]);
  });

  testWidgets('the glass capsule sits on the selected destination', (
    tester,
  ) async {
    for (var i = 0; i < _items.length; i++) {
      await pumpDock(tester, index: i);
      final dock = tester.getRect(find.byType(LiquidGlassNavBar));
      final capsule = tester.getRect(find.byKey(capsuleKey));
      // the dock has 16dp side margins; five equal slots fill the rest
      final inner = dock.width - 32;
      final slot = inner / _items.length;
      final expected = dock.left + 16 + (i + 0.5) * slot;
      expect(
        capsule.center.dx,
        closeTo(expected, 1),
        reason: 'index $i',
      );
      // it stays within the dock horizontally, and overhangs it only slightly
      expect(capsule.left, greaterThanOrEqualTo(dock.left));
      expect(capsule.right, lessThanOrEqualTo(dock.right));
      expect(capsule.top, lessThanOrEqualTo(dock.top));
      expect(dock.top - capsule.top, lessThanOrEqualTo(8));
      expect(capsule.bottom, greaterThanOrEqualTo(dock.bottom));
      expect(capsule.bottom - dock.bottom, lessThanOrEqualTo(8));
    }
  });

  testWidgets('the capsule slides rather than jumping', (tester) async {
    await pumpDock(tester);
    final capsule = tester.widget<AnimatedPositioned>(
      find.ancestor(
        of: find.byKey(capsuleKey),
        matching: find.byType(AnimatedPositioned),
      ),
    );
    expect(capsule.duration, const Duration(milliseconds: 340));
    expect(capsule.curve, Curves.easeInOutCubic);
  });

  testWidgets('the active icon takes the accent from the theme', (
    tester,
  ) async {
    const accents = [
      Color(0xFFEF4444),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFF123456),
    ];
    for (final accent in accents) {
      await pumpDock(tester, accent: accent, index: 2);
      final scheme = Theme.of(
        tester.element(find.byType(LiquidGlassNavBar)),
      ).colorScheme;
      final icons = tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byType(LiquidGlassNavBar),
              matching: find.byType(Icon),
            ),
          )
          .toList();
      expect(icons.length, _items.length);
      expect(icons[2].color, scheme.primary, reason: '$accent active');
      expect(icons[0].color, isNot(scheme.primary), reason: '$accent inactive');
      expect(scheme.primary, AppTheme.adaptAccent(accent, true));
    }
  });

  testWidgets('it renders in light, dark and amoled without complaint', (
    tester,
  ) async {
    await pumpDock(tester, brightness: Brightness.light);
    expect(tester.takeException(), isNull);
    await pumpDock(tester, brightness: Brightness.dark);
    expect(tester.takeException(), isNull);
    await pumpDock(tester, brightness: Brightness.dark, amoled: true);
    expect(tester.takeException(), isNull);
    expect(find.byType(LiquidGlassNavBar), findsOneWidget);
  });

  testWidgets('folding hides the labels but keeps the buttons', (
    tester,
  ) async {
    final compact = await pumpDock(tester);
    expect(find.text('Today'), findsOneWidget);

    compact.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byType(LiquidGlassNavBar), findsOneWidget);
  });

  testWidgets('it fits a 320dp phone with five destinations', (tester) async {
    await pumpDock(tester, width: 320, height: 640);
    expect(tester.takeException(), isNull);
    expect(find.byType(LiquidGlassNavBar), findsOneWidget);
    // the dock must not be wider than the screen
    final box = tester.getSize(find.byType(LiquidGlassNavBar));
    expect(box.width, lessThanOrEqualTo(320));
  });

  testWidgets('with animations off it still selects, just without motion', (
    tester,
  ) async {
    final taps = <int>[];
    await pumpDock(tester, settings: {'animations': false}, onSelect: taps.add);

    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pump();

    expect(taps, [3]);
    final capsule = tester.widget<AnimatedPositioned>(
      find.ancestor(
        of: find.byKey(capsuleKey),
        matching: find.byType(AnimatedPositioned),
      ),
    );
    expect(capsule.duration, Duration.zero);
  });

  testWidgets('the dock keeps to a single blur node', (tester) async {
    await pumpDock(tester);
    final blurs = tester.widgetList<BackdropFilter>(
      find.descendant(
        of: find.byType(LiquidGlassNavBar),
        matching: find.byType(BackdropFilter),
      ),
    );
    expect(blurs.length, 1);
  });

  testWidgets('with glass effects off the dock still builds', (tester) async {
    await pumpDock(tester, settings: {'glassEffects': false});
    expect(tester.takeException(), isNull);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LiquidGlassNavBar), findsOneWidget);
  });
}
