import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';

/// Stores the IC mappings that the user registered, on the device.
abstract interface class IcMappingIF {
  /// Returns every stored IC mapping.
  Future<List<IcMappingEntity>> findAll();

  /// Stores [mapping]. A mapping for the same IC name is replaced.
  Future<void> save(IcMappingEntity mapping);

  /// Removes the mapping of [icName]. Does nothing when there is none.
  Future<void> delete(String icName);
}
