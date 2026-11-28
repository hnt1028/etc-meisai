import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';

/// One line of the usage statement: a single use from an entrance to an exit.
///
/// Amounts are in yen. Only [entranceAt], [entranceIc], [grossFare] and
/// [etcDiscount] can be null, because the CSV leaves them blank in some rows.
class StatementLineEntity {
  const StatementLineEntity({
    this.id,
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
    this.memo = '',
    this.tags = const [],
  });

  /// The id the repository gave when the line was first stored. Null for a
  /// line that was only read from a CSV.
  final String? id;

  /// The entrance date and time. The CSV's, or else the one the user entered
  /// (docs/csv-format.md). Null while both are blank.
  final DateTime? entranceAt;
  final DateTime exitAt;

  /// The entrance IC. The CSV's, or else the one the user entered. Null while
  /// both are blank.
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

  /// Personal information. Never log it. Null when the CSV leaves it blank (a
  /// use that was paid at a toll gate with an ETC card, for instance) and the
  /// user has not entered one (docs/csv-format.md).
  final int? vehicleNumber;

  /// Personal information. Partly masked with `*` in the CSV. Never log it.
  final String cardNumber;

  final ConfirmationStatusValue status;

  /// Discount names from the CSV note, such as 深夜割引. Not part of [status].
  final List<String> discountTypes;

  /// A note of the user. Empty when there is none.
  final String memo;

  /// Labels the user put on the line, such as 仕事. Without `;` and line breaks.
  final List<String> tags;
}
