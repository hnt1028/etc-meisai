import 'package:etc_meisai/domain/entity/app_data_entity.dart';

/// Reads, replaces and deletes everything the app stores on the device (the
/// statement lines, the IC mappings and the IC positions) as a whole.
abstract interface class AppDataIF {
  /// Returns everything that is stored.
  Future<AppDataEntity> readAll();

  /// Deletes everything that is stored, and stores [data] instead. It is one
  /// transaction: when it fails, what was stored stays.
  Future<void> replaceAll(AppDataEntity data);

  /// Deletes everything that is stored. It is one transaction too.
  Future<void> deleteAll();
}
