import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/application/interface/ic_master_if.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';

/// Registers the IC point of an IC name of the CSV. Design: PRC-007.
class SaveIcMappingUC {
  const SaveIcMappingUC({required this.icMaster, required this.icMappings});

  final IcMasterIF icMaster;
  final IcMappingIF icMappings;

  /// Throws [ArgumentError] when [pointId] is not in the IC master.
  Future<void> execute({
    required String icName,
    required String pointId,
  }) async {
    final points = await icMaster.findAll();
    if (!points.any((p) => p.id == pointId)) {
      throw ArgumentError.value(pointId, 'pointId', 'not in the IC master');
    }
    await icMappings.save(IcMappingEntity(icName: icName, pointId: pointId));
  }
}
