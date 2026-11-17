/// The color the user chose for the lines of a road operator on the map.
/// Design: docs/systems/tables/TBL-004-operator-colors.md
class OperatorColorEntity {
  const OperatorColorEntity({required this.operatorName, required this.color});

  /// The road operator, as in docs/aggregation.md ("道路事業者の推定").
  final String operatorName;

  /// The color as an opaque ARGB number, `0xFFRRGGBB`.
  final int color;
}
