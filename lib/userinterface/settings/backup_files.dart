// coverage:ignore-file
// Only wraps the file picker plugin, which opens the system screen and cannot
// run in a test. Tests replace it through backupPickerProvider and
// backupSaverProvider.
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Lets the user choose a backup file. Returns its bytes, or null when the
/// user chose nothing.
typedef BackupPicker = Future<Uint8List?> Function();

/// Lets the user choose where to save a backup file, and saves [bytes] there.
/// Returns false when the user chose nothing.
typedef BackupSaver = Future<bool> Function(String fileName, Uint8List bytes);

Future<Uint8List?> pickBackup() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );
  return file?.readAsBytes();
}

Future<bool> saveBackup(String fileName, Uint8List bytes) async {
  final saved = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: 'application/json',
  );
  return saved != null;
}
