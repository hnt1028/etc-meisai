/// The totals of the filtered statement lines. Design: PRC-013.
class AggregationSummaryDTO {
  const AggregationSummaryDTO({
    required this.lineCount,
    required this.fareTotal,
    required this.discountTotal,
    this.distanceTotal = 0,
    this.distanceUnknownCount = 0,
  });

  final int lineCount;

  /// The total of the fares, in yen.
  final int fareTotal;

  /// The total of the ETC discounts (as positive amounts), in yen.
  final int discountTotal;

  /// The total distance in meters, without the lines whose distance is not
  /// known.
  final int distanceTotal;

  /// How many lines have no distance (docs/aggregation.md).
  final int distanceUnknownCount;
}
