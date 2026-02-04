import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class JsonStorage {
  static Future<String> saveJsonToApiRestReturn(
    Map<String, dynamic> data,
    File originalFile,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final targetDir = Directory(path.join(directory.path, 'APIRest_return'));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final originalName = path.basenameWithoutExtension(originalFile.path);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${originalName}_$timestamp.json';
    final filePath = path.join(targetDir.path, fileName);

    final file = File(filePath);
    final encoder = const JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(data);

    await file.writeAsString(jsonString);

    return filePath;
  }
}
