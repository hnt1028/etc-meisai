import 'package:etc_meisai/application/dto/route_vertex_dto.dart';

/// Every road of the IC master, for the route map. Design: PRC-026.
class RouteNetworkDTO {
  const RouteNetworkDTO({required this.lines, required this.labels});

  /// One line for each link of the master: from a point to the next one,
  /// along the shape of the road.
  final List<RouteNetworkLineDTO> lines;

  /// The name of every road, at one place of the road.
  final List<RouteNetworkLabelDTO> labels;
}

/// The road between two neighboring points.
class RouteNetworkLineDTO {
  const RouteNetworkLineDTO({required this.routeName, required this.points});

  /// The road both points are on. Null when they have none in common.
  final String? routeName;

  /// From the first point to the second, with the bends between them.
  final List<RouteVertexDTO> points;
}

/// Where the name of a road is written.
class RouteNetworkLabelDTO {
  const RouteNetworkLabelDTO({
    required this.routeName,
    required this.latitude,
    required this.longitude,
  });

  final String routeName;
  final double latitude;
  final double longitude;
}
