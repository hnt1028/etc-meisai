import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';

/// One stored row of the statement lines, exactly as it is kept: the values of
/// the CSV and the ones the user entered are apart, and the duplicate key is
/// there. The backup (docs/backup-format.md) uses it, so that a line that is
/// read back is the same row. Unlike [StatementLineEntity], nothing is merged.
class StatementLineRecordEntity {
  const StatementLineRecordEntity({
    required this.id,
    required this.duplicateKey,
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
    required this.enteredEntranceAt,
    required this.enteredEntranceIc,
    required this.cardNumber,
    required this.status,
    required this.discountTypes,
    this.memo = '',
    this.tags = const [],
  });

  final String id;
  final String duplicateKey;

  /// The CSV's entrance. Null when the CSV left it blank.
  final DateTime? entranceAt;
  final DateTime exitAt;
  final String? entranceIc;
  final String exitIc;
  final int? grossFare;
  final int? etcDiscount;
  final int fare;
  final int fareAfterRebate;
  final int postpaidFare;
  final VehicleTypeValue vehicleType;

  /// Personal information. Never log it.
  final int? vehicleNumber;

  /// What the user entered for a blank entrance.
  final DateTime? enteredEntranceAt;
  final String? enteredEntranceIc;

  /// Personal information. Never log it.
  final String cardNumber;
  final ConfirmationStatusValue status;
  final List<String> discountTypes;

  /// A note of the user. Empty when there is none.
  final String memo;

  /// Labels the user put on the line.
  final List<String> tags;
}
