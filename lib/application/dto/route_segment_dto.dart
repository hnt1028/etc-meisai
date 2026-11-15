import 'package:etc_meisai/application/dto/statement_line_dto.dart';

/// One line to draw on the route map: the straight line from the entrance to
/// the exit of a statement line. Design: PRC-009.
class RouteSegmentDTO {
  const RouteSegmentDTO({
    required this.line,
    required this.fromIcName,
    required this.toIcName,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
  });

  final StatementLineDTO line;
  final String fromIcName;
  final String toIcName;
  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;
}
