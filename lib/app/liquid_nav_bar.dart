import 'dart:ui';

import 'package:flutter/physics.dart';

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

/// Identifies the active capsule, so tests can measure it.
const capsuleKey = ValueKey('liquid-nav-capsule');

/// A floating liquid-glass navigation dock.
///
/// Three layers make up the material: a blurred and slightly over-saturated
/// backdrop, a translucent tint over it, and a specular sheen along the upper
/// edge with a hairline border. The selection is a separate glass capsule that
/// sits *inside* the bar — never a solid block — with its own gradient and rim,
/// and it glides between destinations on a spring.
///
/// The accent is never hardcoded: the active icon reads
/// [ColorScheme.primary], so a theme change repaints the dock immediately.
/// With `glassEffects` off the blur is skipped; with animations off the capsule
/// snaps instead of gliding.
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

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with SingleTickerProviderStateMixin {
  static const _tall = 58.0;
  static const _short = 50.0;
  static const _inset = 5.0;
  static const _radius = 30.0;
  static const _ink = Duration(milliseconds: 220);
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 34,
  );

  late final AnimationController _lens;
  bool _folded = false;
  double _velocity = 0;

  @override
  void initState() {
    super.initState();
    _lens = AnimationController.unbounded(
      vsync: this,
      value: widget.index.toDouble(),
    );
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
    if (widget.index != oldWidget.index) _glide();
  }

  @override
  void dispose() {
    widget.compact.removeListener(_onFold);
    _lens.dispose();
    super.dispose();
  }

  void _onFold() {
    if (_folded != widget.compact.value) {
      setState(() => _folded = widget.compact.value);
    }
  }

  bool get _animated {
    final settings = context.read<SettingsController>();
    return settings.animations && !MediaQuery.disableAnimationsOf(context);
  }

  void _glide() {
    final target = widget.index.toDouble();
    if (!_animated) {
      _velocity = 0;
      _lens.value = target;
      return;
    }
    final from = _lens.value;
    final simulation = SpringSimulation(_spring, from, target, _velocity);
    _velocity = simulation.dx(0);
    _lens.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final amoled = dark && settings.amoled;
    final scheme = Theme.of(context).colorScheme;
    final glass = settings.glassEffects;
    final animate =
        settings.animations && !MediaQuery.disableAnimationsOf(context);
    final ink = animate ? _ink : Duration.zero;

    final height = _folded ? _short : _tall;
    final count = widget.items.length;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedContainer(
          duration: ink,
          curve: Curves.easeOutCubic,
          height: height,
          child: LayoutBuilder(
            builder: (context, box) {
              final slot = box.maxWidth / count;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: _glass(
                      dark: dark,
                      amoled: amoled,
                      glass: glass,
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _lens,
                      builder: (context, _) {
                        final pos = _lens.value.clamp(0.0, count - 1.0);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: pos * slot + _inset,
                              top: _inset,
                              bottom: _inset,
                              width: slot - _inset * 2,
                              child: _capsule(
                                dark: dark,
                                amoled: amoled,
                                scheme: scheme,
                              ),
                            ),
                          ],
                        );
                      },
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

  /// Layer 1 + 2: blurred, over-saturated backdrop under a translucent tint,
  /// finished with a specular sheen along the top edge and a hairline border.
  Widget _glass({
    required bool dark,
    required bool amoled,
    required bool glass,
  }) {
    final tint = amoled
        ? [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.015),
          ]
        : dark
        ? [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.03),
          ]
        : [
            Colors.white.withValues(alpha: 0.52),
            Colors.white.withValues(alpha: 0.34),
          ];
    final edge = amoled
        ? Colors.white.withValues(alpha: 0.18)
        : dark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.85);
    final sheen = dark || amoled
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.75);

    final body = Stack(
      fit: StackFit.expand,
      children: [
        // translucent tint over the blurred backdrop
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: tint,
            ),
          ),
        ),
        // reflection along the upper edge
        Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: 0.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [sheen, sheen.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
        // inner highlight under the top edge, and the hairline rim
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: edge),
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.34 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: glass ? BackdropFilter(filter: _backdrop(), child: body) : body,
      ),
    );
  }

  /// Blur with a gentle saturation lift, so colours behind the glass stay alive
  /// instead of turning grey the way a plain blur leaves them.
  ImageFilter _backdrop() {
    const s = 1.28;
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final i = 1 - s;
    final matrix = <double>[
      lr * i + s, lg * i, lb * i, 0, 0, //
      lr * i, lg * i + s, lb * i, 0, 0, //
      lr * i, lg * i, lb * i + s, 0, 0, //
      0, 0, 0, 1, 0,
    ];
    return ImageFilter.compose(
      outer: ColorFilter.matrix(matrix),
      inner: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
    );
  }

  /// Layer 3: the selection capsule. Glass, not a solid block: a low-alpha
  /// gradient, a bright rim and a soft drop shadow so it floats over the bar.
  Widget _capsule({
    required bool dark,
    required bool amoled,
    required ColorScheme scheme,
  }) {
    final fill = amoled
        ? [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
          ]
        : dark
        ? [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.07),
          ]
        : [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.62),
          ];
    final rim = dark || amoled
        ? Colors.white.withValues(alpha: 0.42)
        : Colors.white;

    return DecoratedBox(
      key: capsuleKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fill,
        ),
        border: Border.all(color: rim, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: dark ? 0.26 : 0.18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.ink,
    required this.onTap,
  });

  final LiquidNavItem item;
  final bool active;
  final Duration ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = active
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.88);

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
            child: AnimatedScale(
              scale: active ? 1.1 : 1,
              duration: ink,
              curve: Curves.easeOutCubic,
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
          ),
        ),
      ),
    );
  }
}
