import 'package:etc_meisai/domain/entity/vehicle_type_division_entity.dart';

/// Reads the vehicle type divisions (the master bundled with the app).
abstract interface class VehicleTypeMasterIF {
  /// Returns every vehicle type division.
  Future<List<VehicleTypeDivisionEntity>> findAll();
}
