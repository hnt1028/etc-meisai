import 'dart:typed_data';

import 'package:etc_meisai/domain/entity/app_data_entity.dart';

/// The file format of the backup (docs/backup-format.md).
abstract interface class BackupIF {
  /// Makes the content of a backup file of [data], made at [exportedAt].
  Uint8List encode(AppDataEntity data, DateTime exportedAt);

  /// Reads the content of a backup file.
  ///
  /// Throws a [FormatException] when it does not meet the checks of
  /// docs/backup-format.md. The message says which part is wrong, and never
  /// includes a value of the file: it can be personal data.
  AppDataEntity decode(Uint8List bytes);
}
