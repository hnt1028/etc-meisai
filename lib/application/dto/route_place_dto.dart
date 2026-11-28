import 'package:etc_meisai/domain/value/ic_place_source_value.dart';

/// A marker of the route map. Design: PRC-009.
class RoutePlaceDTO {
  const RoutePlaceDTO({
    required this.icName,
    required this.latitude,
    required this.longitude,
    required this.source,
    required this.approximate,
    required this.routeNames,
    required this.lineCount,
  });

  /// The IC name as written in the CSV.
  final String icName;
  final double latitude;
  final double longitude;
  final IcPlaceSourceValue source;

  /// True when the position is borrowed from the IC of the same name.
  final bool approximate;

  /// The routes of the IC point. Empty when the position was specified.
  final List<String> routeNames;

  /// How many statement lines have this IC name.
  final int lineCount;
}
