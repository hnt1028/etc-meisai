import 'package:etc_meisai/application/dto/aggregation_row_dto.dart';
import 'package:etc_meisai/application/dto/aggregation_summary_dto.dart';

/// What the aggregation screen shows. Design: PRC-013.
class AggregationDTO {
  const AggregationDTO({
    required this.summary,
    required this.weeks,
    required this.months,
    required this.years,
    required this.operators,
    required this.routes,
    required this.ics,
    required this.hours,
    required this.discountTypes,
    this.routesOtherCount = 0,
    this.icsOtherCount = 0,
    required this.vehicleNumberChoices,
    required this.cardNumberChoices,
    this.tags = const [],
    this.tagChoices = const [],
  });

  final AggregationSummaryDTO summary;

  /// By period, the newest first. A week is named by its Monday.
  final List<AggregationRowDTO> weeks;
  final List<AggregationRowDTO> months;
  final List<AggregationRowDTO> years;

  /// By road operator (estimated from the route names), the largest fare first.
  final List<AggregationRowDTO> operators;

  /// The top 10 routes by count. Fare and discount are null.
  final List<AggregationRowDTO> routes;

  /// The top 10 ICs by count. Fare and discount are null.
  final List<AggregationRowDTO> ics;

  /// The 24 hours of the exit time, from 0.
  final List<AggregationRowDTO> hours;

  /// The total count of the routes and ICs that are not in the top 10.
  final int routesOtherCount;
  final int icsOtherCount;

  /// By discount type, the most used first. Fare is null.
  final List<AggregationRowDTO> discountTypes;

  /// Values the user can filter by. They come from all stored statement lines.
  final List<int> vehicleNumberChoices;

  /// The last 4 characters of each card number.
  final List<String> cardNumberChoices;

  /// The rows for each tag, and for the lines without a tag.
  final List<AggregationRowDTO> tags;

  /// Every tag of the stored lines, sorted.
  final List<String> tagChoices;
}
