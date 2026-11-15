// coverage:ignore-file
// Only wraps the file picker plugin, which opens the system screen and cannot
// run in a test. Tests replace it through csvPickerProvider.
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Lets the user choose a CSV file. Returns its bytes, or null when the user
/// chose nothing.
typedef CsvPicker = Future<Uint8List?> Function();

Future<Uint8List?> pickCsv() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['csv'],
  );
  return file?.readAsBytes();
}
