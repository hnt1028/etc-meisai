import 'package:etc_meisai/application/dto/route_place_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';

/// The route of one statement line, for the statement detail screen.
/// Design: PRC-012.
class LineRouteDTO {
  const LineRouteDTO({
    required this.segment,
    required this.places,
    required this.unlocatedIcNames,
    this.meters,
  });

  /// The line to draw. Null when it cannot be drawn: the entrance is blank, or
  /// a position is not known.
  final RouteSegmentDTO? segment;

  /// The markers: the entrance, then the exit.
  final List<RoutePlaceDTO> places;

  /// The IC names whose position is not known: the entrance, then the exit.
  final List<String> unlocatedIcNames;

  /// The distance of the line in meters (docs/aggregation.md, "距離の求め方").
  /// Null when it is not known: the entrance is blank, or a position is not
  /// known.
  final int? meters;
}
