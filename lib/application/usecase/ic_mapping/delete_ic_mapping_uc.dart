import 'package:etc_meisai/application/interface/ic_mapping_if.dart';

/// Removes the registered IC point of an IC name. Design: PRC-008.
class DeleteIcMappingUC {
  const DeleteIcMappingUC({required this.icMappings});

  final IcMappingIF icMappings;

  Future<void> execute(String icName) => icMappings.delete(icName);
}
