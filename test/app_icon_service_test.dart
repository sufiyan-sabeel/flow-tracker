import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_tracker/services/app_icon_service.dart';

/// Exercises the launcher-icon channel contract: the service must report what
/// the native side actually did, and must never claim a switch that failed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('streak/app_icon');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;

  void mock(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls = [];
    AppIconService.debugSupported = true;
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    AppIconService.debugSupported = null;
  });

  test('maps each index to its alias key', () {
    expect(AppIconService.nameFor(0), 'default');
    expect(AppIconService.nameFor(1), 'neutral');
    expect(AppIconService.nameFor(2), 'accent');
    // out of range falls back to the nearest valid entry rather than throwing
    expect(AppIconService.nameFor(-5), 'default');
    expect(AppIconService.nameFor(99), 'accent');
  });

  test('apply reports success from the native side', () async {
    mock((call) async => true);
    expect(await AppIconService.apply(2), isTrue);
    expect(calls.single.method, 'setIcon');
    expect(calls.single.arguments, {'icon': 'accent'});
  });

  test(
    'apply reports failure when the component update did not happen',
    () async {
      mock((call) async => false);
      expect(await AppIconService.apply(1), isFalse);
    },
  );

  test('apply reports failure when the platform throws', () async {
    mock((call) async => throw PlatformException(code: 'boom'));
    expect(await AppIconService.apply(1), isFalse);
  });

  test('apply is a no-op on a platform without launcher switching', () async {
    AppIconService.debugSupported = false;
    expect(await AppIconService.apply(1), isFalse);
    expect(calls, isEmpty);
  });

  test('current returns the enabled alias, and null when ambiguous', () async {
    mock((call) async => 'neutral');
    expect(await AppIconService.current(), 'neutral');

    messenger.setMockMethodCallHandler(channel, (call) async => null);
    expect(await AppIconService.current(), isNull);
  });

  test('reconcile does nothing when the launcher already matches', () async {
    mock((call) async => call.method == 'currentIcon' ? 'accent' : true);
    expect(await AppIconService.reconcile(2), isFalse);
    expect(calls.map((c) => c.method), ['currentIcon']);
  });

  test('reconcile repairs a launcher that drifted from the preference', () async {
    mock((call) async => call.method == 'currentIcon' ? 'default' : true);
    expect(await AppIconService.reconcile(2), isTrue);
    expect(calls.map((c) => c.method), ['currentIcon', 'setIcon']);
    expect(calls.last.arguments, {'icon': 'accent'});
  });

  test('reconcile repairs an ambiguous component state', () async {
    // null means several aliases are enabled, or none
    mock((call) async => call.method == 'currentIcon' ? null : true);
    expect(await AppIconService.reconcile(1), isTrue);
    expect(calls.last.arguments, {'icon': 'neutral'});
  });
}
