/// A point of a line of the route map. Design: PRC-009.
class RouteVertexDTO {
  const RouteVertexDTO({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
