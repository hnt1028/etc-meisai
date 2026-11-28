/// A position the user chose on the map for an IC name of the CSV.
class IcPositionEntity {
  const IcPositionEntity({
    required this.icName,
    required this.latitude,
    required this.longitude,
  });

  /// The IC name as written in the CSV.
  final String icName;

  /// Degrees.
  final double latitude;
  final double longitude;
}
