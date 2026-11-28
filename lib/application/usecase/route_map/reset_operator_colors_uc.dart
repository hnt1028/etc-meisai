import 'package:etc_meisai/application/interface/operator_color_if.dart';

/// Takes back the colors the user chose, so that the defaults are used.
/// Design: PRC-023.
class ResetOperatorColorsUC {
  const ResetOperatorColorsUC({required this.operatorColors});

  final OperatorColorIF operatorColors;

  /// Resets the color of [operatorName], or all of them when it is null.
  Future<void> execute({String? operatorName}) {
    return operatorName == null
        ? operatorColors.deleteAll()
        : operatorColors.delete(operatorName);
  }
}
