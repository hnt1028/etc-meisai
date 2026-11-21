import 'package:etc_meisai/application/dto/route_segment_dto.dart';

/// The line of a segment is the same road as another when both join the same
/// two ICs, in either direction.
String segmentRoadKey(RouteSegmentDTO segment) {
  final names = [segment.fromIcName, segment.toIcName]..sort();
  return names.join('\u0000');
}

/// How many segments there are for each road ([segmentRoadKey]).
Map<String, int> segmentCounts(Iterable<RouteSegmentDTO> segments) {
  final counts = <String, int>{};
  for (final s in segments) {
    counts.update(segmentRoadKey(s), (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
}

/// The usual width of a line.
const segmentBaseWidth = 4.0;

/// The width of a line driven [count] times: 2 more for each time, up to the
/// fifth.
double segmentWidth(int count) =>
    segmentBaseWidth + 2 * (count - 1).clamp(0, 4);

/// The names of roads are written from this zoom: below it, they would cover
/// the map.
const networkNamesMinZoom = 9.0;
