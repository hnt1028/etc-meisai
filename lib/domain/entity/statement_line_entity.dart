import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';

/// One line of the usage statement: a single use from an entrance to an exit.
///
/// Amounts are in yen. Only [entranceAt], [entranceIc], [grossFare] and
/// [etcDiscount] can be null, because the CSV leaves them blank in some rows.
class StatementLineEntity {
  const StatementLineEntity({
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
    required this.cardNumber,
    required this.status,
    required this.discountTypes,
  });

  /// May be null when the CSV leaves the entrance blank.
  final DateTime? entranceAt;
  final DateTime exitAt;

  /// May be null when the CSV leaves the entrance blank.
  final String? entranceIc;
  final String exitIc;

  /// Null (not 0) when the CSV leaves it blank, i.e. no discount applied.
  final int? grossFare;

  /// Null (not 0) when the CSV leaves it blank, i.e. no discount applied.
  final int? etcDiscount;

  final int fare;
  final int fareAfterRebate;
  final int postpaidFare;

  final VehicleTypeValue vehicleType;

  /// Personal information. Never log it.
  final int vehicleNumber;

  /// Personal information. Partly masked with `*` in the CSV. Never log it.
  final String cardNumber;

  final ConfirmationStatusValue status;

  /// Discount names from the CSV note, such as 深夜割引. Not part of [status].
  final List<String> discountTypes;
}
