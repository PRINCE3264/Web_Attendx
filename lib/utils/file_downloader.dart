import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

abstract class FileDownloader {
  static Future<String?> saveAndDownloadFile({
    required String content,
    required String filename,
    List<int>? bytes,
    String mimeType = 'text/csv;charset=utf-8',
  }) {
    return saveAndDownloadFileImpl(
      content: content,
      filename: filename,
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
