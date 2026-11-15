import 'package:etc_meisai/application/dto/route_place_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/dto/unlocated_ic_dto.dart';

/// What the route map screen shows. Design: PRC-009.
class RouteMapDTO {
  const RouteMapDTO({
    required this.segments,
    required this.places,
    required this.unlocated,
    required this.undrawnLineCount,
    required this.lineCount,
    required this.vehicleNumberChoices,
    required this.cardNumberChoices,
  });

  /// The lines to draw.
  final List<RouteSegmentDTO> segments;

  /// The markers, in the order of the IC name.
  final List<RoutePlaceDTO> places;

  /// The IC names whose position is not known, the most used first.
  final List<UnlocatedIcDTO> unlocated;

  /// How many statement lines could not be drawn: a position is not known, or
  /// the entrance is blank.
  final int undrawnLineCount;

  /// How many statement lines meet the filter.
  final int lineCount;

  /// Values the user can filter by. They come from all stored statement lines.
  final List<int> vehicleNumberChoices;

  /// The last 4 characters of each card number.
  final List<String> cardNumberChoices;
}
