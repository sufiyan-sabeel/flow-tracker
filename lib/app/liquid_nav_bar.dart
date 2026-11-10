import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flow_tracker/core/widgets/glass.dart';
import 'package:flow_tracker/features/settings/state/settings_controller.dart';

/// One destination in the liquid glass dock.
class LiquidNavItem {
  const LiquidNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// A floating, translucent navigation dock with a sliding glass capsule behind
/// the active destination.
///
/// The accent colour is never hardcoded: the capsule, the selected icon and the
/// selected label all read [ColorScheme.primary], so switching the accent in
/// Settings repaints the dock immediately. When `glassEffects` is off — or the
/// platform asks for reduced motion — the blur is dropped and the transitions
/// collapse to a cross-fade, which keeps the dock cheap on low-end devices.
class LiquidGlassNavBar extends StatefulWidget {
  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
    required this.compact,
  });

  final List<LiquidNavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  /// Folds the labels away while the user scrolls, as the classic bar does.
  final ValueListenable<bool> compact;

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> {
  static const _radius = 30.0;
  static const _tall = 68.0;
  static const _short = 54.0;
  static const _slide = Duration(milliseconds: 340);
  static const _ink = Duration(milliseconds: 210);
  static const _curve = Curves.easeInOutCubic;

  bool _folded = false;

  @override
  void initState() {
    super.initState();
    _folded = widget.compact.value;
    widget.compact.addListener(_onFold);
  }

  @override
  void didUpdateWidget(LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.compact != oldWidget.compact) {
      oldWidget.compact.removeListener(_onFold);
      widget.compact.addListener(_onFold);
    }
  }

  @override
  void dispose() {
    widget.compact.removeListener(_onFold);
    super.dispose();
  }

  void _onFold() {
    if (_folded != widget.compact.value) {
      setState(() => _folded = widget.compact.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final media = MediaQuery.of(context);
    // Honour both the in-app switch and the platform's reduced-motion setting.
    final animate = settings.animations && !media.disableAnimations;
    final slide = animate ? _slide : Duration.zero;
    final ink = animate ? _ink : Duration.zero;
    final glass = settings.glassEffects;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final amoled = dark && settings.amoled;

    final height = _folded ? _short : _tall;
    final count = widget.items.length;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedContainer(
          duration: slide,
          curve: _curve,
          height: height,
          decoration: _shell(dark: dark, amoled: amoled),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: glass
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: _surface(
                      context,
                      dark: dark,
                      amoled: amoled,
                      count: count,
                      slide: slide,
                      ink: ink,
                    ),
                  )
                : _surface(
                    context,
                    dark: dark,
                    amoled: amoled,
                    count: count,
                    slide: slide,
                    ink: ink,
                  ),
          ),
        ),
      ),
    );
  }

  /// Outer shadow only: the tint and the hairline border live on [_surface] so
  /// the blur sits behind them instead of washing them out.
  BoxDecoration _shell({required bool dark, required bool amoled}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_radius),
      boxShadow: [
        if (amoled)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(0, 8),
          )
        else if (dark)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 26,
            offset: const Offset(0, 10),
          )
        else
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
      ],
    );
  }

  Widget _surface(
    BuildContext context, {
    required bool dark,
    required bool amoled,
    required int count,
    required Duration slide,
    required Duration ink,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tint = amoled
        ? [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.02),
          ]
        : dark
        ? [
            Colors.white.withValues(alpha: 0.11),
            Colors.white.withValues(alpha: 0.04),
          ]
        : [
            Colors.white.withValues(alpha: 0.78),
            Colors.white.withValues(alpha: 0.62),
          ];
    final edge = amoled
        ? Colors.white.withValues(alpha: 0.16)
        : dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint,
        ),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: edge),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final slot = box.maxWidth / count;
          return Stack(
            children: [
              AnimatedAlign(
                alignment: Alignment((2 * widget.index + 1) / count - 1, 0),
                duration: slide,
                curve: _curve,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    width: slot - 10,
                    decoration: _capsule(
                      dark: dark,
                      amoled: amoled,
                      scheme: scheme,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: _NavButton(
                        item: widget.items[i],
                        active: i == widget.index,
                        folded: _folded,
                        ink: ink,
                        onTap: () => widget.onSelect(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  BoxDecoration _capsule({
    required bool dark,
    required bool amoled,
    required ColorScheme scheme,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: amoled
            ? [
                Colors.white.withValues(alpha: 0.13),
                Colors.white.withValues(alpha: 0.06),
              ]
            : dark
            ? [
                Colors.white.withValues(alpha: 0.17),
                Colors.white.withValues(alpha: 0.09),
              ]
            : [Colors.white, Colors.white.withValues(alpha: 0.86)],
      ),
      border: Border.all(
        color: scheme.primary.withValues(alpha: dark ? 0.34 : 0.30),
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.22),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.folded,
    required this.ink,
    required this.onTap,
  });

  final LiquidNavItem item;
  final bool active;
  final bool folded;
  final Duration ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = active
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.86);

    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Pressable(
          onTap: onTap,
          scale: 0.92,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: active ? 1.08 : 1,
                  duration: ink,
                  curve: Curves.easeInOutCubic,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: colour),
                    duration: ink,
                    builder: (context, value, _) => Icon(
                      item.icon,
                      size: 22,
                      color: value ?? colour,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: ink,
                  curve: Curves.easeInOutCubic,
                  child: folded
                      ? const SizedBox(width: 0, height: 0)
                      : Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: AnimatedDefaultTextStyle(
                            duration: ink,
                            curve: Curves.easeInOutCubic,
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.1,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.2,
                              color: colour,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
