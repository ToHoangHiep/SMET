import 'dart:html' as html;
import 'dart:typed_data';

void downloadPdfWeb(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..setAttribute('target', '_blank');
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

void openPdfInNewTab(String pdfUrl) {
  html.window.open(pdfUrl, '_blank');
}
