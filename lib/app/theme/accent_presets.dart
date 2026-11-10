import 'package:flutter/material.dart';
import 'package:flow_tracker/app/theme/app_palette.dart';
import 'package:flow_tracker/core/utils/hex_color.dart';

/// A named accent colour the user can pick in one tap.
class AccentPreset {
  const AccentPreset({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;

  /// Brand names stay in English in every locale.
  final String name;
  final Color color;

  String get hex => hexOf(color);
}

class AccentPresets {
  const AccentPresets._();

  /// The ten shipped presets, in menu order.
  static const all = <AccentPreset>[
    AccentPreset(id: 'flow_teal', name: 'Flow Teal', color: Color(0xFF14B8A6)),
    AccentPreset(id: 'ocean_blue', name: 'Ocean Blue', color: Color(0xFF3B82F6)),
    AccentPreset(
      id: 'royal_purple',
      name: 'Royal Purple',
      color: Color(0xFF8B5CF6),
    ),
    AccentPreset(
      id: 'emerald_green',
      name: 'Emerald Green',
      color: Color(0xFF10B981),
    ),
    AccentPreset(
      id: 'sunset_orange',
      name: 'Sunset Orange',
      color: Color(0xFFF97316),
    ),
    AccentPreset(id: 'rose_pink', name: 'Rose Pink', color: Color(0xFFEC4899)),
    AccentPreset(
      id: 'crimson_red',
      name: 'Crimson Red',
      color: Color(0xFFEF4444),
    ),
    AccentPreset(id: 'amber_gold', name: 'Amber Gold', color: Color(0xFFF59E0B)),
    AccentPreset(id: 'slate_gray', name: 'Slate Gray', color: Color(0xFF64748B)),
    AccentPreset(id: 'indigo', name: 'Indigo', color: Color(0xFF6366F1)),
  ];

  /// The accent Flow-tracker ships with; the target of "reset".
  static Color get defaultColor => AppPalette.brand;

  static AccentPreset? byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  static AccentPreset? byColor(Color color) {
    for (final preset in all) {
      if (preset.color.toARGB32() == color.toARGB32()) return preset;
    }
    return null;
  }

  static bool isPreset(Color color) => byColor(color) != null;

  static bool isDefault(Color color) =>
      color.toARGB32() == defaultColor.toARGB32();
}
