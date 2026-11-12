import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Switches the Android launcher icon.
///
/// The launcher entry is an `activity-alias`: exactly one alias is enabled at a
/// time, and each one points at its own icon resource. The native side owns the
/// component state; this class only asks for a change and reports whether it
/// actually happened.
class AppIconService {
  const AppIconService._();

  static const _channel = MethodChannel('streak/app_icon');

  /// Index to alias key, in the same order as the Appearance sheet.
  static const names = ['default', 'neutral', 'accent'];

  /// Launcher switching is an Android-only capability. iOS has no equivalent
  /// public API, so the channel simply does not exist there.
  static bool get supported => _supportedOverride ?? Platform.isAndroid;

  static bool? _supportedOverride;

  /// Lets a test exercise the Android path on a host that is not Android.
  @visibleForTesting
  static set debugSupported(bool? value) => _supportedOverride = value;

  static String nameFor(int index) => names[index.clamp(0, names.length - 1)];

  static Future<Color?> systemAccent() async {
    if (!supported) return null;
    try {
      final value = await _channel.invokeMethod<int>('systemAccent');
      return value == null ? null : Color(value);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Applies [index] and returns whether the launcher component was updated.
  ///
  /// Callers must not persist a selection when this returns false.
  static Future<bool> apply(int index) async {
    if (!supported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('setIcon', {
        'icon': nameFor(index),
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The alias that currently owns the launcher entry, or null when the state is
  /// ambiguous (no alias enabled, or several).
  static Future<String?> current() async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<String>('currentIcon');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Re-aligns the launcher with the stored preference after a start-up, a
  /// restore, or a switch that failed halfway. Does nothing when they agree.
  ///
  /// Returns true when a repair was needed and succeeded.
  static Future<bool> reconcile(int index) async {
    if (!supported) return false;
    final want = nameFor(index);
    final have = await current();
    if (have == want) return false;
    return apply(index);
  }
}
