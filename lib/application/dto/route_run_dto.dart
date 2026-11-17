import 'package:etc_meisai/application/dto/route_vertex_dto.dart';

/// A part of the line of a route map that is on the roads of one operator.
/// The parts of a line are drawn in the colors of their operators. Design:
/// PRC-009.
class RouteRunDTO {
  const RouteRunDTO({required this.operator, required this.points});

  /// The road operator (docs/aggregation.md, "道路事業者の推定"), or
  /// `unknownOperator` when it is not known.
  final String operator;

  /// The points from the start of the part to its end, both included. The end
  /// of a part is the start of the next one.
  final List<RouteVertexDTO> points;
}
