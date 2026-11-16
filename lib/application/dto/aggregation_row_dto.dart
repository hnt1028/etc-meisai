/// One row of an aggregation. Design: PRC-013.
class AggregationRowDTO {
  const AggregationRowDTO({
    required this.label,
    required this.count,
    this.fare,
    this.discount,
  });

  /// The name of the row: a period ("2026/01/05", "2026/01", "2026"), an
  /// operator, a route, an IC, an hour ("0" to "23") or a discount type.
  final String label;

  /// How many statement lines.
  final int count;

  /// The total fare in yen. Null when the aggregation does not give it.
  final int? fare;

  /// The total discount in yen. Null when the aggregation does not give it.
  final int? discount;
}
