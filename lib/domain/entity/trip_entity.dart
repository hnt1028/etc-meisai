import '../value/confirmation_status_value.dart';

/// One trip from an entrance to an exit (one row of the usage statement CSV).
///
/// Amounts are in yen. Only [entranceAt], [entranceIc], [grossFare] and
/// [etcDiscount] can be null, because the CSV leaves them blank in some rows.
class TripEntity {
  const TripEntity({
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

  final String vehicleType;

  /// Personal information. Never log it.
  final String vehicleNumber;

  /// Personal information. Partly masked with `*` in the CSV. Never log it.
  final String cardNumber;

  final ConfirmationStatusValue status;

  /// Discount names from the CSV note, such as 深夜割引. Not part of [status].
  final List<String> discountTypes;
}
