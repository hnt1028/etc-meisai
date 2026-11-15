import 'package:etc_meisai/domain/entity/ic_point_entity.dart';

/// Reads the IC master (the points bundled with the app).
abstract interface class IcMasterIF {
  /// Returns every IC point.
  Future<List<IcPointEntity>> findAll();
}
