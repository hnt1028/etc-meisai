import 'package:etc_meisai/application/dto/route_run_dto.dart';
import 'package:etc_meisai/application/dto/route_vertex_dto.dart';
import 'package:etc_meisai/application/dto/statement_line_dto.dart';

/// One line to draw on the route map: from the entrance, through the points
/// between, to the exit of a statement line. Design: PRC-009.
class RouteSegmentDTO {
  const RouteSegmentDTO({
    required this.line,
    required this.fromIcName,
    required this.toIcName,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
    this.via = const [],
    this.runs = const [],
  });

  final StatementLineDTO line;
  final String fromIcName;
  final String toIcName;
  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;

  /// The points between the entrance and the exit, in order. Empty when the
  /// line is straight.
  final List<RouteVertexDTO> via;

  /// The same line from the entrance to the exit, cut where the operator of
  /// the road changes. Empty only when the line is not given a color by
  /// operator.
  final List<RouteRunDTO> runs;
}
