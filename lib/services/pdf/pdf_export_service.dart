import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flow_tracker/services/pdf/pdf_export_options.dart';
import 'package:flow_tracker/services/pdf/pdf_report_builder.dart';
import 'package:flow_tracker/services/pdf/pdf_report_data.dart';
import 'package:flow_tracker/services/pdf/pdf_theme.dart';

/// Result of a save attempt, so the UI can tell "cancelled" from "failed".
enum PdfSaveResult { saved, cancelled, failed }

/// Generates, names, saves and shares reports. Everything runs on the device:
/// the only I/O is reading the local database and writing the file the user
/// picked. No network calls exist in this file.
class PdfExportService {
  const PdfExportService._();

  /// Builds the PDF bytes for [options]. Pure apart from reading the database
  /// and the bundled fonts, which makes it usable from tests.
  static Future<Uint8List> generate(
    PdfExportOptions options, {
    DateTime? today,
    String version = 'Flow-tracker',
  }) async {
    final resolved = options.resolve(today ?? DateTime.now());
    final data = ReportData.load(
      from: resolved.from,
      to: resolved.to,
      today: today,
    );
    final base = pw.Font.ttf(
      await rootBundle.load('fonts/Figtree-Regular.ttf'),
    );
    final bold = pw.Font.ttf(await rootBundle.load('fonts/Figtree-Bold.ttf'));
    final style = PdfStyle(
      PdfTheme.of(options.theme, options.accent),
      base: base,
      bold: bold,
    );
    final builder = PdfReportBuilder(
      options: options,
      data: data,
      style: style,
      generatedAt: today ?? DateTime.now(),
      version: version,
    );
    return builder.build().save();
  }

  /// `FlowTracker_Complete_Report_2026-11-10.pdf` and friends.
  static String fileName(PdfExportOptions options, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final resolved = options.resolve(now);
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp = switch (options.type) {
      PdfExportType.monthly => '${resolved.to.year}-${two(resolved.to.month)}',
      PdfExportType.yearly => '${resolved.to.year}',
      _ =>
        '${resolved.to.year}-${two(resolved.to.month)}-${two(resolved.to.day)}',
    };
    return 'FlowTracker_${options.type.fileStem}_$stamp.pdf';
  }

  /// Writes the bytes to a private temp file. Used for sharing, where the
  /// receiving app needs a real file that outlives the call.
  static Future<File> writeTemp(Uint8List bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final folder = Directory('${dir.path}/flow_tracker_reports');
    if (!await folder.exists()) await folder.create(recursive: true);
    final file = File('${folder.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Opens Android's save dialog (Storage Access Framework) and writes the file
  /// where the user points. Returns [PdfSaveResult.cancelled] if they back out.
  static Future<PdfSaveResult> saveAs(
    Uint8List bytes,
    String name, {
    bool isMobile = true,
  }) async {
    try {
      if (isMobile) {
        // On Android this goes through ACTION_CREATE_DOCUMENT; the plugin writes
        // the bytes itself, so no shared-storage permission is needed.
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save report',
          fileName: name,
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
        );
        return path == null ? PdfSaveResult.cancelled : PdfSaveResult.saved;
      }
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save report',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (path == null) return PdfSaveResult.cancelled;
      await File(path).writeAsBytes(bytes, flush: true);
      return PdfSaveResult.saved;
    } catch (_) {
      return PdfSaveResult.failed;
    }
  }

  /// Hands the PDF to Android's share sheet. The temp file is kept alive by the
  /// receiving app's own copy; we do not delete it out from under the share.
  static Future<bool> share(
    Uint8List bytes,
    String name, {
    Rect? origin,
    String subject = 'Flow-tracker report',
  }) async {
    try {
      final file = await writeTemp(bytes, name);
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: subject,
        sharePositionOrigin: origin,
      );
      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (_) {
      return false;
    }
  }

  /// Deletes leftover temp reports. User-saved copies are untouched because they
  /// live wherever the user chose, not in the app's temp folder.
  static Future<void> clearTemp() async {
    try {
      final dir = await getTemporaryDirectory();
      final folder = Directory('${dir.path}/flow_tracker_reports');
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (_) {
      // Nothing to clean up, or the folder is busy: not worth surfacing.
    }
  }
}
