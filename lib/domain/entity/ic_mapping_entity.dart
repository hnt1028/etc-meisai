/// An IC name of the CSV that the user tied to an IC point.
class IcMappingEntity {
  const IcMappingEntity({required this.icName, required this.pointId});

  /// The IC name as written in the CSV.
  final String icName;

  /// The id of the IC point in the IC master.
  final String pointId;
}
