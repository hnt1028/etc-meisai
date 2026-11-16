/// The totals of the filtered statement lines. Design: PRC-013.
class AggregationSummaryDTO {
  const AggregationSummaryDTO({
    required this.lineCount,
    required this.fareTotal,
    required this.discountTotal,
  });

  final int lineCount;

  /// The total of the fares, in yen.
  final int fareTotal;

  /// The total of the ETC discounts (as positive amounts), in yen.
  final int discountTotal;
}
