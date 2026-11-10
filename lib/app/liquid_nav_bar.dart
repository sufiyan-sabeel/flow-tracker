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

/// Identifies the sliding lens, so tests can measure it.
const capsuleKey = ValueKey('liquid-nav-capsule');

/// A floating, translucent navigation dock.
///
/// The bar itself is a blurred glass pill; the selection is a *lens* that sits
/// above that glass and overhangs it slightly, the way a real glass bead would
/// catch the light on a surface. Only the selected destination carries a label,
/// which keeps the bar quiet and gives the active item the weight.
///
/// The accent is never hardcoded: the lens glow, the selected icon and its label
/// all read [ColorScheme.primary], so changing the accent in Settings repaints
/// the dock immediately. With `glassEffects` off the blur node is skipped
/// entirely; with animations off every transition collapses to zero duration.
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

  /// Folds the bar down while the user scrolls, as the old bar did.
  final ValueListenable<bool> compact;

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> {
  static const _radius = 32.0;
  static const _tall = 58.0;
  static const _short = 48.0;
  static const _overhang = 4.0;
  static const _inset = 2.0;
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
    final scheme = Theme.of(context).colorScheme;

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
          // The lens overhangs the pill, so nothing here may clip.
          child: LayoutBuilder(
            builder: (context, box) {
              final slot = box.maxWidth / count;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: _pill(
                      context,
                      dark: dark,
                      amoled: amoled,
                      glass: glass,
                    ),
                  ),
                  // Positioned by slot: the inset is part of the maths, or the
                  // lens drifts off its destination.
                  AnimatedPositioned(
                    left: widget.index * slot + _inset,
                    top: -_overhang,
                    bottom: -_overhang,
                    width: slot - _inset * 2,
                    duration: slide,
                    curve: _curve,
                    child: DecoratedBox(
                      key: capsuleKey,
                      decoration: _lens(
                        dark: dark,
                        amoled: amoled,
                        scheme: scheme,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
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
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The glass pill: shadow outside, blur and tint inside the clip.
  Widget _pill(
    BuildContext context, {
    required bool dark,
    required bool amoled,
    required bool glass,
  }) {
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

    final surface = Container(
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
    );

    return DecoratedBox(
      decoration: BoxDecoration(
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: glass
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: surface,
              )
            : surface,
      ),
    );
  }

  /// The selection lens: an opaque glass bead with a bright rim that lifts off
  /// the bar and carries a whisper of the accent in its glow.
  BoxDecoration _lens({
    required bool dark,
    required bool amoled,
    required ColorScheme scheme,
  }) {
    final fill = amoled
        ? [const Color(0xFF17171A), const Color(0xFF0A0A0C)]
        : dark
        ? [const Color(0xFF26262B), const Color(0xFF151518)]
        : [Colors.white, const Color(0xFFF1F1F6)];
    final rim = amoled
        ? Colors.white.withValues(alpha: 0.34)
        : dark
        ? Colors.white.withValues(alpha: 0.46)
        : Colors.white;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(_radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: fill,
      ),
      border: Border.all(color: rim, width: 1.4),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: dark ? 0.30 : 0.22),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.45 : 0.16),
          blurRadius: 16,
          offset: const Offset(0, 6),
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
    final showLabel = active && !folded;

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
                  scale: active ? 1.06 : 1,
                  duration: ink,
                  curve: _LiquidGlassNavBarState._curve,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: colour),
                    duration: ink,
                    builder: (context, value, _) => Icon(
                      item.icon,
                      size: 21,
                      color: value ?? colour,
                    ),
                  ),
                ),
                // Only the selected destination is named: it keeps the bar
                // quiet and gives the lens something to hold.
                AnimatedSize(
                  duration: ink,
                  curve: _LiquidGlassNavBarState._curve,
                  child: showLabel
                      ? Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: AnimatedDefaultTextStyle(
                            duration: ink,
                            curve: _LiquidGlassNavBarState._curve,
                            // Inherit the app's font: a bare TextStyle here
                            // would fall back to the platform default.
                            style: DefaultTextStyle.of(context).style.copyWith(
                              fontSize: 10,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: colour,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : const SizedBox(width: 0, height: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
