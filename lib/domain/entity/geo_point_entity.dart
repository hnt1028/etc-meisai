/// A position on the map, in degrees. A point of the shape of a road.
class GeoPointEntity {
  const GeoPointEntity({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
