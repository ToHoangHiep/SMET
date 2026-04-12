import 'dart:developer';
import 'dart:html' as html; // Web-only
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:smet/service/report/report_service.dart';

// ================================================================
// FILE DOWNLOAD UTILITY
// Handles cross-platform file download (web)
// Backend returns bytes → trigger browser download
// ================================================================

class FileDownloadUtil {
  static void _log(String msg) {
    log('[FileDownload] $msg');
  }

  /// Download file bytes with browser save-as dialog
  static void downloadBytes({
    required ExportResult result,
  }) {
    if (!kIsWeb) {
      _log('downloadBytes: only supported on web platform');
      return;
    }

    try {
      final blob = html.Blob([result.bytes], result.mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', result.fileName)
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      _log('Downloaded: ${result.fileName} (${result.bytes.length} bytes)');
    } catch (e) {
      _log('Download error: $e');
    }
  }

  /// Trigger download for raw bytes (non-web platforms)
  static void downloadBytesRaw({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) {
    if (!kIsWeb) {
      _log('downloadBytesRaw: only supported on web platform');
      return;
    }

    try {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      _log('Downloaded: $fileName (${bytes.length} bytes)');
    } catch (e) {
      _log('Download error: $e');
    }
  }
}
