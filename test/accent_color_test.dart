import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tracker/app/theme/accent_presets.dart';
import 'package:flow_tracker/app/theme/app_palette.dart';
import 'package:flow_tracker/app/theme/app_theme.dart';
import 'package:flow_tracker/core/utils/hex_color.dart';
import 'package:flow_tracker/features/settings/state/settings_controller.dart';

import 'support/app_harness.dart';

void main() {
  useEmptyStore();

  group('presets', () {
    test('ships the ten requested accents in order', () {
      expect(AccentPresets.all.length, 10);
      expect(AccentPresets.all.map((preset) => preset.hex).toList(), [
        '#14B8A6',
        '#3B82F6',
        '#8B5CF6',
        '#10B981',
        '#F97316',
        '#EC4899',
        '#EF4444',
        '#F59E0B',
        '#64748B',
        '#6366F1',
      ]);
      expect(AccentPresets.all.map((preset) => preset.id).toSet().length, 10);
    });

    test('a preset can be found by id and by colour', () {
      expect(AccentPresets.byId('flow_teal')?.name, 'Flow Teal');
      expect(AccentPresets.byColor(const Color(0xFF14B8A6))?.id, 'flow_teal');
      expect(AccentPresets.byColor(const Color(0xFF123456)), isNull);
      expect(AccentPresets.byId('nope'), isNull);
      expect(AccentPresets.isPreset(const Color(0xFF123456)), isFalse);
    });

    test('the default is the shipped brand colour', () {
      expect(AccentPresets.defaultColor, AppPalette.brand);
      expect(AccentPresets.isDefault(AppPalette.brand), isTrue);
      expect(AccentPresets.isDefault(const Color(0xFF14B8A6)), isFalse);
    });
  });

  group('hex input', () {
    test('accepts the forms people actually type', () {
      expect(parseHexColor('#14B8A6'), const Color(0xFF14B8A6));
      expect(parseHexColor('14b8a6'), const Color(0xFF14B8A6));
      expect(parseHexColor('  #14b8a6  '), const Color(0xFF14B8A6));
      expect(parseHexColor('0x14B8A6'), const Color(0xFF14B8A6));
      expect(parseHexColor('#0AF'), const Color(0xFF00AAFF));
    });

    test('rejects anything that is not a colour', () {
      const bad = [
        '',
        '   ',
        '#',
        '#12345',
        'zzzzzz',
        'rgb(1,2,3)',
        '#1234567',
        '#14B8A6FF',
        'teal',
      ];
      for (final input in bad) {
        expect(parseHexColor(input), isNull, reason: input);
      }
    });

    test('round-trips every preset through its hex', () {
      for (final preset in AccentPresets.all) {
        expect(parseHexColor(preset.hex), preset.color);
        expect(hexOf(preset.color), preset.hex);
      }
    });
  });

  group('accent in every mode', () {
    test('the chosen accent becomes the primary colour', () {
      for (final preset in AccentPresets.all) {
        expect(
          AppTheme.light(preset.color).colorScheme.primary,
          AppTheme.adaptAccent(preset.color, false),
          reason: preset.name,
        );
        expect(
          AppTheme.dark(preset.color).colorScheme.primary,
          AppTheme.adaptAccent(preset.color, true),
          reason: preset.name,
        );
      }
    });

    test('every accent stays visible against its own surface', () {
      for (final preset in AccentPresets.all) {
        for (final isDark in [false, true]) {
          final theme = isDark
              ? AppTheme.dark(preset.color)
              : AppTheme.light(preset.color);
          expect(
            contrastRatio(theme.colorScheme.primary, theme.colorScheme.surface),
            greaterThanOrEqualTo(3.0),
            reason: '${preset.name} on ${isDark ? 'dark' : 'light'}',
          );
        }
      }
    });

    test('text sitting on the accent stays readable', () {
      for (final preset in AccentPresets.all) {
        for (final isDark in [false, true]) {
          final scheme = isDark
              ? AppTheme.dark(preset.color).colorScheme
              : AppTheme.light(preset.color).colorScheme;
          expect(
            contrastRatio(scheme.primary, scheme.onPrimary),
            greaterThanOrEqualTo(3.0),
            reason: preset.name,
          );
        }
      }
    });

    test('amoled keeps the accent on a pure black surface', () {
      final theme = AppTheme.dark(const Color(0xFF14B8A6), 0, null, true);
      expect(theme.colorScheme.surface, Colors.black);
      expect(
        theme.colorScheme.primary,
        AppTheme.adaptAccent(const Color(0xFF14B8A6), true),
      );
      expect(
        contrastRatio(theme.colorScheme.primary, theme.colorScheme.surface),
        greaterThanOrEqualTo(3.0),
      );
    });

    test('the three interface styles all honour the accent', () {
      for (var style = 0; style < 3; style++) {
        final theme = AppTheme.light(const Color(0xFFEC4899), style);
        expect(
          theme.colorScheme.primary,
          isNot(Colors.black),
          reason: '$style',
        );
      }
    });
  });

  group('persistence', () {
    test('the chosen accent survives a restart', () async {
      final first = SettingsController();
      expect(first.accentColor, AppPalette.brand);

      await first.setAccentColor(const Color(0xFFEC4899));
      await coldStart();

      expect(SettingsController().accentColor, const Color(0xFFEC4899));
    });

    test('with nothing saved the default comes back', () async {
      await coldStart();
      expect(SettingsController().accentColor, AppPalette.brand);
    });

    test('a custom colour round-trips, not just presets', () async {
      final first = SettingsController();
      await first.setAccentColor(const Color(0xFF123456));
      await coldStart();
      expect(SettingsController().accentColor, const Color(0xFF123456));
    });
  });
}
