import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flow_tracker/core/i18n/app_locale.dart';
import 'package:flow_tracker/app/app_background.dart';
import 'package:flow_tracker/app/app_lock.dart';
import 'package:flow_tracker/app/home_shell.dart';
import 'package:flow_tracker/app/theme/app_theme.dart';
import 'package:flow_tracker/core/i18n/l10n.dart';
import 'package:flow_tracker/core/routing/app_navigator.dart';
import 'package:flow_tracker/core/utils/responsive.dart';
import 'package:flow_tracker/core/widgets/sheet_swipe_close.dart';
import 'package:flow_tracker/features/habits/state/habits_controller.dart';
import 'package:flow_tracker/features/onboarding/pages/onboarding_page.dart';
import 'package:flow_tracker/features/settings/state/settings_controller.dart';
import 'package:flow_tracker/services/home_widget_service.dart';

class FlowTrackerApp extends StatelessWidget {
  const FlowTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MaterialApp(
      title: 'Flow-tracker',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      theme: AppTheme.light(
        settings.accentColor,
        settings.appStyle,
        settings.colorTheme,
      ),
      darkTheme: AppTheme.dark(
        settings.accentColor,
        settings.appStyle,
        settings.colorTheme,
        settings.amoled,
      ),
      themeMode: settings.themeMode,
      builder: (context, child) {
        HomeWidgetService.localize(
          AppLocalizations.of(context),
          () => context.read<HabitsController>().asMap,
        );
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: settings.animations
              ? media
              : media.copyWith(disableAnimations: true),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.systemBars(Theme.of(context).brightness),
            child: AppLockGate(
              child: AppBackground(
                child: _DesktopFrame(
                  shell: settings.onboardingDone,
                  child: SheetSwipeClose(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      locale: settings.locale,
      supportedLocales: shippedLocales,
      localeListResolutionCallback: (wanted, _) => pickLocale(wanted),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: settings.onboardingDone
          ? const HomeShell()
          : const OnboardingPage(),
    );
  }
}

class _DesktopFrame extends StatelessWidget {
  const _DesktopFrame({required this.shell, required this.child});

  final bool shell;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || (shell && hasSideRail(context))) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: phoneWidth),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}
