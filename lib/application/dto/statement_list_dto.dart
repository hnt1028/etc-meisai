import 'package:etc_meisai/application/dto/statement_line_dto.dart';

/// What the statement list screen shows. Design: PRC-004.
class StatementListDTO {
  const StatementListDTO({
    required this.lines,
    required this.totalFare,
    required this.totalFareAfterRebate,
    required this.totalPostpaidFare,
    required this.vehicleNumberChoices,
    required this.cardNumberChoices,
  });

  /// The filtered statement lines, newest exit first.
  final List<StatementLineDTO> lines;

  /// Sums over [lines], in yen.
  final int totalFare;
  final int totalFareAfterRebate;
  final int totalPostpaidFare;

  /// Values the user can filter by. They come from all stored statement lines,
  /// not only from [lines].
  final List<int> vehicleNumberChoices;

  /// The last 4 characters of each card number (never the whole number).
  final List<String> cardNumberChoices;
}
