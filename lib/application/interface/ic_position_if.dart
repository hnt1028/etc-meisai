import 'package:etc_meisai/domain/entity/ic_position_entity.dart';

/// Stores the positions the user chose on the map, on the device.
abstract interface class IcPositionIF {
  /// Returns every stored position.
  Future<List<IcPositionEntity>> findAll();

  /// Stores [position]. A position for the same IC name is replaced.
  Future<void> save(IcPositionEntity position);

  /// Removes the position of [icName]. Does nothing when there is none.
  Future<void> delete(String icName);
}
