import 'package:etc_meisai/application/interface/operator_color_if.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/domain/entity/operator_color_entity.dart';

/// Stores the color the user chose for the lines of a road operator.
/// Design: PRC-022.
class SaveOperatorColorUC {
  const SaveOperatorColorUC({required this.operatorColors});

  final OperatorColorIF operatorColors;

  /// [color] is the ARGB number; the alpha is made opaque. Throws an
  /// [ArgumentError] for an operator that is not in the route operators table.
  Future<void> execute({required String operatorName, required int color}) {
    if (!knownOperators.contains(operatorName)) {
      throw ArgumentError.value(operatorName, 'operatorName');
    }
    return operatorColors.save(
      OperatorColorEntity(
        operatorName: operatorName,
        color: 0xFF000000 | (color & 0xFFFFFF),
      ),
    );
  }
}
