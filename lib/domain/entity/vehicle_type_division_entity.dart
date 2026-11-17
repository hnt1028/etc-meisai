/// A vehicle type division: the names of the vehicle type numbers 1 to 5 of a
/// road operator (or of some roads of it). See docs/vehicle-types.md.
class VehicleTypeDivisionEntity {
  const VehicleTypeDivisionEntity({
    required this.id,
    required this.operators,
    required this.roads,
    required this.names,
  });

  final String id;

  /// The road operators the division is for (the names of the route operators
  /// table, docs/aggregation.md).
  final List<String> operators;

  /// Words of the road names the division is only for. Empty for the division
  /// of every road of the operators that no other division takes.
  final List<String> roads;

  /// The names of the vehicle type numbers 1 to 5, in this order. Null for a
  /// number the division does not have.
  final List<String?> names;
}
