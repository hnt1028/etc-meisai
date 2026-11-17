import 'package:etc_meisai/application/dto/operator_color_dto.dart';
import 'package:etc_meisai/application/interface/operator_color_if.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/application/usecase/route_map/operator_default_colors.dart';

/// Lists the color of the lines of every road operator: the one the user
/// chose, or else the default. Design: PRC-021.
class ListOperatorColorsUC {
  const ListOperatorColorsUC({required this.operatorColors});

  final OperatorColorIF operatorColors;

  /// In the order of the route operators table.
  Future<List<OperatorColorDTO>> execute() async {
    final chosen = {
      for (final c in await operatorColors.findAll()) c.operatorName: c.color,
    };
    return [
      for (final name in knownOperators)
        OperatorColorDTO(
          operatorName: name,
          color: chosen[name] ?? defaultOperatorColors[name]!,
          isDefault: !chosen.containsKey(name),
        ),
    ];
  }
}
