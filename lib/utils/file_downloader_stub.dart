import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> saveAndDownloadFileImpl({
  required String content,
  required String filename,
  List<int>? bytes,
  String mimeType = 'text/csv;charset=utf-8',
}) async {
  try {
    Directory? dir;
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        dir = downloadDir;
      } else {
        dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$filename');
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    } else {
      await file.writeAsString(content);
    }
    return file.path;
  } catch (e) {
    debugPrint('Native file save error: $e');
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      } else {
        await file.writeAsString(content);
      }
      return file.path;
    } catch (e2) {
      return null;
    }
  }
}
