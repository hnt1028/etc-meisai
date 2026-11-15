import 'package:etc_meisai/domain/value/confirmation_status_value.dart';

/// One row of the statement list screen. Design: PRC-004.
///
/// It leaves out the vehicle number and the card number, which the screen
/// does not show for each row.
class StatementLineDTO {
  const StatementLineDTO({
    required this.entranceAt,
    required this.exitAt,
    required this.entranceIc,
    required this.exitIc,
    required this.fare,
    required this.status,
  });

  /// Null when the CSV leaves the entrance blank.
  final DateTime? entranceAt;
  final DateTime exitAt;

  /// Null when the CSV leaves the entrance blank.
  final String? entranceIc;
  final String exitIc;

  final int fare;
  final ConfirmationStatusValue status;
}
