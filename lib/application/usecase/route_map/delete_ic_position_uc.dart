import 'package:etc_meisai/application/interface/ic_position_if.dart';

/// Removes the position the user chose for an IC name. Design: PRC-011.
class DeleteIcPositionUC {
  const DeleteIcPositionUC({required this.icPositions});

  final IcPositionIF icPositions;

  Future<void> execute(String icName) => icPositions.delete(icName);
}
