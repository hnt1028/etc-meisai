import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';

/// One statement line for the statement list, the timeline and the detail
/// screen. Design: PRC-004.
///
/// It holds the card number only as its last 4 characters.
class StatementLineDTO {
  const StatementLineDTO({
    required this.entranceAt,
    required this.exitAt,
    required this.entranceIc,
    required this.exitIc,
    required this.grossFare,
    required this.etcDiscount,
    required this.fare,
    required this.fareAfterRebate,
    required this.postpaidFare,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.cardNumberSuffix,
    required this.status,
    required this.discountTypes,
  });

  /// Null when the CSV leaves the entrance blank.
  final DateTime? entranceAt;
  final DateTime exitAt;

  /// Null when the CSV leaves the entrance blank.
  final String? entranceIc;
  final String exitIc;

  /// Null (not 0) when no discount applied.
  final int? grossFare;

  /// Null (not 0) when no discount applied.
  final int? etcDiscount;

  final int fare;
  final int fareAfterRebate;
  final int postpaidFare;

  final VehicleTypeValue vehicleType;

  /// Personal information. Never log it.
  final int vehicleNumber;

  /// The last 4 characters of the card number.
  final String cardNumberSuffix;

  final ConfirmationStatusValue status;

  /// Discount names such as 深夜割引. Empty when there is none.
  final List<String> discountTypes;
}
