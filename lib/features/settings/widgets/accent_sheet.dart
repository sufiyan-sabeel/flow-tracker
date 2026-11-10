import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' as cp;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flow_tracker/app/theme/accent_presets.dart';
import 'package:flow_tracker/core/i18n/l10n.dart';
import 'package:flow_tracker/core/utils/hex_color.dart';
import 'package:flow_tracker/core/widgets/sheet_type.dart';
import 'package:flow_tracker/features/settings/state/settings_controller.dart';
import 'package:flow_tracker/features/settings/widgets/settings_sheets.dart';
import 'package:flow_tracker/services/app_icon_service.dart';

/// Accent colour picker: presets, a custom picker, a hex field and a live
/// preview. Nothing is written until the user taps Apply.
Future<void> showAccentSheet(BuildContext context) =>
    showSheet(context, (_) => const _AccentSheet());

class _AccentSheet extends StatefulWidget {
  const _AccentSheet();

  @override
  State<_AccentSheet> createState() => _AccentSheetState();
}

class _AccentSheetState extends State<_AccentSheet> {
  late Color _draft;
  late final TextEditingController _hex;
  String? _hexError;
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    _draft = context.read<SettingsController>().accentColor;
    _hex = TextEditingController(text: hexOf(_draft));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _select(Color color) {
    setState(() {
      _draft = color;
      _hexError = null;
      _hex.text = hexOf(color);
    });
  }

  void _onHexChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() => _hexError = null);
      return;
    }
    final parsed = parseHexColor(value);
    setState(() {
      _hexError = parsed == null ? context.l10n.invalid_hex : null;
      if (parsed != null) _draft = parsed;
    });
  }

  void _reset() => _select(AccentPresets.defaultColor);

  void _apply() {
    context.read<SettingsController>().setAccentColor(_draft);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetTitle(l10n.accent_color),
            const SizedBox(height: 14),
            _AccentPreview(color: _draft),
            const SizedBox(height: 18),
            _SectionLabel(text: l10n.color_presets),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FutureBuilder<Color?>(
                  future: AppIconService.systemAccent(),
                  builder: (context, snapshot) {
                    final system = snapshot.data;
                    if (system == null) return const SizedBox.shrink();
                    return _PresetChip(
                      label: l10n.system,
                      color: system,
                      selected: system.toARGB32() == _draft.toARGB32(),
                      onTap: () => _select(system),
                    );
                  },
                ),
                for (final preset in AccentPresets.all)
                  _PresetChip(
                    label: preset.name,
                    color: preset.color,
                    selected: preset.color.toARGB32() == _draft.toARGB32(),
                    onTap: () => _select(preset.color),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hex,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              onChanged: _onHexChanged,
              decoration: InputDecoration(
                labelText: l10n.hex_code,
                errorText: _hexError,
                prefixIcon: const Icon(LucideIcons.hash, size: 18),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _draft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => setState(() => _pickerOpen = !_pickerOpen),
              icon: Icon(
                _pickerOpen ? LucideIcons.chevronUp : LucideIcons.pipette,
                size: 18,
              ),
              label: Text(l10n.custom),
            ),
            if (_pickerOpen)
              Center(
                child: cp.HueRingPicker(
                  pickerColor: _draft,
                  onColorChanged: _select,
                  enableAlpha: false,
                  displayThumbColor: true,
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _reset,
                icon: const Icon(LucideIcons.rotateCcw, size: 18),
                label: Text(l10n.reset_color),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: _draft,
                    foregroundColor: _draft.computeLuminance() > 0.179
                        ? Colors.black
                        : Colors.white,
                  ),
                  child: Text(l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label ${hexOf(color)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: selected
                    ? Icon(
                        LucideIcons.check,
                        size: 13,
                        color: color.computeLuminance() > 0.179
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sample controls painted with the colour being considered, so the choice can
/// be judged before it is applied to the whole app.
class _AccentPreview extends StatelessWidget {
  const _AccentPreview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onColor = color.computeLuminance() > 0.179
        ? Colors.black
        : Colors.white;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionLabel(text: context.l10n.preview),
              const Spacer(),
              Text(
                hexOf(color),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: onColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 38),
                ),
                child: Text(context.l10n.sample_button),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.flame, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Switch(value: true, onChanged: (_) {}, activeThumbColor: color),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.62,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.check, size: 17, color: onColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.sample_habit,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '12 ${context.l10n.days}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '86%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
