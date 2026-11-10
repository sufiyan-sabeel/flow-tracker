import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:flow_tracker/core/extensions/inset_extensions.dart';
import 'package:flow_tracker/core/i18n/l10n.dart';
import 'package:flow_tracker/core/utils/app_snackbar.dart';
import 'package:flow_tracker/features/settings/state/settings_controller.dart';
import 'package:flow_tracker/services/pdf/pdf_export_options.dart';
import 'package:flow_tracker/services/pdf/pdf_export_service.dart';
import 'package:flow_tracker/services/pdf/pdf_theme.dart';

/// The PDF export dashboard: what to export, over which days, which sections,
/// and which document design. Everything it produces is generated on-device.
class PdfExportPage extends StatefulWidget {
  const PdfExportPage({super.key});

  @override
  State<PdfExportPage> createState() => _PdfExportPageState();
}

class _PdfExportPageState extends State<PdfExportPage> {
  PdfExportType _type = PdfExportType.complete;
  PdfDateRange _range = PdfDateRange.last30;
  late Set<PdfSection> _sections = {..._type.defaultSections};
  PdfThemeId _theme = PdfThemeId.executive;
  DateTime? _from;
  DateTime? _to;
  bool _busy = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // version is only used in the footer, so a failure is not worth surfacing
    }
  }

  PdfExportOptions get _options => PdfExportOptions(
    type: _type,
    range: _range,
    sections: _sections,
    theme: _theme,
    accent: context.read<SettingsController>().accentColor,
    from: _from,
    to: _to,
  );

  void _pickType(PdfExportType type) {
    setState(() {
      _type = type;
      _sections = {...type.defaultSections};
      final natural = type.naturalRange;
      if (natural != null) _range = natural;
    });
  }

  Future<void> _run(
    Future<void> Function(PdfExportOptions options) action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    // let the progress state paint before the (synchronous) document build
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      await action(_options);
    } catch (error) {
      if (mounted) AppSnackbar.error(context, 'Could not create the PDF');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview() => _run((options) async {
    final bytes = await PdfExportService.generate(options, version: _version);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PdfPreviewPage(
          title: options.type.label,
          bytes: bytes,
        ),
      ),
    );
  });

  Future<void> _save() => _run((options) async {
    final bytes = await PdfExportService.generate(options, version: _version);
    final name = PdfExportService.fileName(options);
    final result = await PdfExportService.saveAs(bytes, name);
    if (!mounted) return;
    switch (result) {
      case PdfSaveResult.saved:
        AppSnackbar.success(context, 'Saved $name');
      case PdfSaveResult.cancelled:
        break;
      case PdfSaveResult.failed:
        AppSnackbar.error(context, 'Could not save the PDF');
    }
  });

  Future<void> _share() => _run((options) async {
    // captured before the await so no context is used across an async gap
    final box = context.findRenderObject() as RenderBox?;
    final bytes = await PdfExportService.generate(options, version: _version);
    final name = PdfExportService.fileName(options);
    final ok = await PdfExportService.share(
      bytes,
      name,
      origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      subject: '${options.type.label} — Flow-tracker',
    );
    if (!ok && mounted) AppSnackbar.error(context, 'Could not share the PDF');
  });

  Future<void> _pickCustomDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
      _range = PdfDateRange.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = _options.resolve(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pdf_export)),
      body: Stack(
        children: [
          ListView(
            padding: context.pagePadding(16, 8, 16, 120),
            children: [
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.pdf_export_sub,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendarRange,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _range == PdfDateRange.all
                                ? 'All history, from your first record'
                                : '${_fmt(resolved.from)} → ${_fmt(resolved.to)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _heading(context, 'Export type'),
              _card(
                context,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in PdfExportType.values)
                      _chip(
                        context,
                        label: type.label,
                        selected: _type == type,
                        onTap: () => _pickType(type),
                      ),
                  ],
                ),
              ),
              _heading(context, 'Date range'),
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final range in PdfDateRange.values)
                          _chip(
                            context,
                            label: range.label,
                            selected: _range == range,
                            onTap: () => setState(() => _range = range),
                          ),
                      ],
                    ),
                    if (_range == PdfDateRange.custom) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickCustomDate(isFrom: true),
                              child: Text(
                                _from == null ? 'From…' : _fmt(_from!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickCustomDate(isFrom: false),
                              child: Text(_to == null ? 'To…' : _fmt(_to!)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _heading(context, 'Include'),
              _card(
                context,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final section in PdfSection.values)
                      CheckboxListTile(
                        value: _sections.contains(section),
                        onChanged: (on) => setState(() {
                          if (on ?? false) {
                            _sections.add(section);
                          } else {
                            _sections.remove(section);
                          }
                        }),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: Text(
                          section.label,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                  ],
                ),
              ),
              _heading(context, 'Document theme'),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: PdfThemeId.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final id = PdfThemeId.values[i];
                    final theme = PdfTheme.ui(
                      id,
                      context.watch<SettingsController>().accentColor,
                    );
                    final selected = _theme == id;
                    return GestureDetector(
                      onTap: () => setState(() => _theme = id),
                      child: Container(
                        width: 132,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.page,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? scheme.primary
                                : scheme.outlineVariant,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: theme.accent,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 30,
                                  height: 5,
                                  color: theme.ink,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(height: 4, color: theme.rule),
                            const SizedBox(height: 4),
                            Container(height: 4, color: theme.rule),
                            const Spacer(),
                            Text(
                              id.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: theme.ink,
                              ),
                            ),
                            Text(
                              id.blurb,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                height: 1.2,
                                color: theme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _preview,
                      icon: const Icon(LucideIcons.eye, size: 17),
                      label: const Text('Preview'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _share,
                      icon: const Icon(LucideIcons.share2, size: 17),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: const Icon(LucideIcons.download, size: 17),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Reports are generated on your phone from your own data. '
                'Nothing is uploaded, and no connection is needed.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: scheme.scrim.withValues(alpha: 0.25),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Building report…',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _card(
    BuildContext context, {
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.14)
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Renders the actual generated PDF with the platform renderer: pages, zoom and
/// scrolling all come from the real document, not a mock-up.
class _PdfPreviewPage extends StatelessWidget {
  const _PdfPreviewPage({required this.title, required this.bytes});

  final String title;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (format) async => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        pdfFileName: title,
      ),
    );
  }
}
