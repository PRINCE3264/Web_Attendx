import 'dart:convert';
import 'dart:html' as html;

Future<String?> saveAndDownloadFileImpl({
  required String content,
  required String filename,
  List<int>? bytes,
  String mimeType = 'text/csv;charset=utf-8',
}) async {
  try {
    final fileBytes = bytes ?? utf8.encode(content);
    // Add UTF-8 BOM (\uFEFF) for Excel compatibility if text/csv file
    final finalBytes = (mimeType.contains('csv') ||
            mimeType.contains('excel') ||
            filename.endsWith('.csv') ||
            filename.endsWith('.xlsx') ||
            filename.endsWith('.tsv'))
        ? [0xEF, 0xBB, 0xBF, ...fileBytes]
        : fileBytes;

    final blob = html.Blob([finalBytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    return 'Downloads/$filename';
  } catch (e) {
    return null;
  }
}
