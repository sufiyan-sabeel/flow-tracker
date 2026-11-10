import 'package:flutter/material.dart';

/// Parses a colour typed by the user.
///
/// Accepts `#RRGGBB`, `RRGGBB`, `#RGB` and `RGB`, with an optional `0x` prefix.
/// Returns null for anything else so callers can show a validation message
/// instead of silently guessing a colour.
Color? parseHexColor(String input) {
  var text = input.trim();
  if (text.startsWith('#')) text = text.substring(1);
  if (text.startsWith('0x') || text.startsWith('0X')) text = text.substring(2);
  if (text.isEmpty) return null;
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(text)) return null;
  if (text.length == 3) {
    text = text.split('').map((char) => '$char$char').join();
  }
  if (text.length != 6) return null;
  final value = int.tryParse(text, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

/// The `#RRGGBB` form of [color], for showing in a text field.
String hexOf(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// WCAG contrast ratio between two colours, from 1 (identical) to 21.
double contrastRatio(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}
