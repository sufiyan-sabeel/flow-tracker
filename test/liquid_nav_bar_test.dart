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

  /// Where the capsule sits relative to the bar, in slots.
  double slotOf(WidgetTester tester) {
    final dock = tester.getRect(find.byType(LiquidGlassNavBar));
    final capsule = tester.getRect(find.byKey(capsuleKey));
    final slot = (dock.width - 32) / _items.length;
    return (capsule.center.dx - dock.left - 16) / slot - 0.5;
  }

  testWidgets('every destination is announced to screen readers', (
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
    // the reference has no labels on the bar, and neither do we
    for (final item in _items) {
      expect(find.text(item.label), findsNothing, reason: item.label);
    }
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

  testWidgets('the capsule sits on the selected destination, inside the bar', (
    tester,
  ) async {
    for (var i = 0; i < _items.length; i++) {
      await pumpDock(tester, index: i);
      expect(slotOf(tester), closeTo(i.toDouble(), 0.06), reason: 'index $i');

      final dock = tester.getRect(find.byType(LiquidGlassNavBar));
      final capsule = tester.getRect(find.byKey(capsuleKey));
      // the capsule is inset inside the bar, never spilling out of it
      expect(capsule.top, greaterThanOrEqualTo(dock.top));
      expect(capsule.bottom, lessThanOrEqualTo(dock.bottom));
      expect(capsule.left, greaterThanOrEqualTo(dock.left));
      expect(capsule.right, lessThanOrEqualTo(dock.right));
      // and it is a capsule, not a slab: rounded, inset, narrower than a slot
      expect(capsule.height, lessThan(dock.height));
    }
  });

  testWidgets('the capsule glides instead of jumping', (tester) async {
    await pumpDock(tester);
    expect(slotOf(tester), closeTo(0, 0.06));

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsController>.value(
        value: SettingsController(),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: LiquidGlassNavBar(
                items: _items,
                index: 4,
                onSelect: (_) {},
                compact: ValueNotifier(false),
              ),
            ),
          ),
        ),
      ),
    );
    // a moment in, it is on its way rather than already there
    await tester.pump(const Duration(milliseconds: 60));
    final mid = slotOf(tester);
    expect(mid, greaterThan(0.0));
    expect(mid, lessThan(4.0));

    await tester.pumpAndSettle();
    expect(slotOf(tester), closeTo(4, 0.06));
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

  testWidgets('folding makes the bar shorter', (tester) async {
    final compact = await pumpDock(tester);
    final tall = tester.getSize(find.byType(LiquidGlassNavBar)).height;

    compact.value = true;
    await tester.pumpAndSettle();

    final short = tester.getSize(find.byType(LiquidGlassNavBar)).height;
    expect(short, lessThan(tall));
    expect(find.byType(LiquidGlassNavBar), findsOneWidget);
  });

  testWidgets('it fits a 320dp phone with five destinations', (tester) async {
    await pumpDock(tester, width: 320, height: 640);
    expect(tester.takeException(), isNull);
    final box = tester.getSize(find.byType(LiquidGlassNavBar));
    expect(box.width, lessThanOrEqualTo(320));
  });

  testWidgets('with animations off the capsule snaps, but still selects', (
    tester,
  ) async {
    final taps = <int>[];
    await pumpDock(tester, settings: {'animations': false}, onSelect: taps.add);

    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pump();
    expect(taps, [3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the glass is a blur, and drops out when effects are off', (
    tester,
  ) async {
    await pumpDock(tester);
    final blurs = tester.widgetList<BackdropFilter>(
      find.descendant(
        of: find.byType(LiquidGlassNavBar),
        matching: find.byType(BackdropFilter),
      ),
    );
    expect(blurs.length, 1);

    await pumpDock(tester, settings: {'glassEffects': false});
    expect(tester.takeException(), isNull);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LiquidGlassNavBar), findsOneWidget);
  });
}
