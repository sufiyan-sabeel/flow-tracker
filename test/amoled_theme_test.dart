import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tracker/app/theme/app_theme.dart';

void main() {
  group('true black theme', () {
    test('dark theme is not pure black by default', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.surface, isNot(Colors.black));
    });

    test('amoled dark theme paints surfaces pure black', () {
      final theme = AppTheme.dark(null, 0, null, true);
      expect(theme.colorScheme.surface, Colors.black);
      expect(theme.colorScheme.surfaceContainer, const Color(0xFF0C0C0C));
      expect(theme.cardTheme.color, const Color(0xFF0A0A0A));
    });

    test('amoled leaves the light theme alone', () {
      final plain = AppTheme.light();
      final withFlag = AppTheme.light(null, 0, null);
      expect(withFlag.colorScheme.surface, plain.colorScheme.surface);
      expect(withFlag.colorScheme.surface, isNot(Colors.black));
    });

    test('amoled reaches the express style too', () {
      final theme = AppTheme.dark(null, 2, null, true);
      expect(theme.colorScheme.surface, Colors.black);
    });

    test('amoled keeps the accent colour readable', () {
      final theme = AppTheme.dark(const Color(0xFF7C3AED), 0, null, true);
      expect(theme.colorScheme.primary, isNot(Colors.black));
      expect(
        theme.colorScheme.onSurface.computeLuminance(),
        greaterThan(theme.colorScheme.surface.computeLuminance()),
      );
    });
  });
}
