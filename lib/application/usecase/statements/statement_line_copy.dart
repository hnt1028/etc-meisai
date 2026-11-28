import 'package:etc_meisai/domain/entity/statement_line_entity.dart';

/// The same line with the vehicle number [vehicleNumber]. An Entity only holds
/// values, so the copies are made here (docs/architecture.md).
StatementLineEntity copyWithVehicleNumber(
  StatementLineEntity line,
  int vehicleNumber,
) => StatementLineEntity(
  id: line.id,
  entranceAt: line.entranceAt,
  exitAt: line.exitAt,
  entranceIc: line.entranceIc,
  exitIc: line.exitIc,
  grossFare: line.grossFare,
  etcDiscount: line.etcDiscount,
  fare: line.fare,
  fareAfterRebate: line.fareAfterRebate,
  postpaidFare: line.postpaidFare,
  vehicleType: line.vehicleType,
  vehicleNumber: vehicleNumber,
  cardNumber: line.cardNumber,
  status: line.status,
  discountTypes: line.discountTypes,
  memo: line.memo,
  tags: line.tags,
);

/// The same line with the entrance the user entered. A null argument keeps
/// what the line has.
StatementLineEntity copyWithEntrance(
  StatementLineEntity line, {
  DateTime? entranceAt,
  String? entranceIc,
}) => StatementLineEntity(
  id: line.id,
  entranceAt: entranceAt ?? line.entranceAt,
  exitAt: line.exitAt,
  entranceIc: entranceIc ?? line.entranceIc,
  exitIc: line.exitIc,
  grossFare: line.grossFare,
  etcDiscount: line.etcDiscount,
  fare: line.fare,
  fareAfterRebate: line.fareAfterRebate,
  postpaidFare: line.postpaidFare,
  vehicleType: line.vehicleType,
  vehicleNumber: line.vehicleNumber,
  cardNumber: line.cardNumber,
  status: line.status,
  discountTypes: line.discountTypes,
  memo: line.memo,
  tags: line.tags,
);

/// The same line with the memo and the tags of the user.
StatementLineEntity copyWithNote(
  StatementLineEntity line, {
  required String memo,
  required List<String> tags,
}) => StatementLineEntity(
  id: line.id,
  entranceAt: line.entranceAt,
  exitAt: line.exitAt,
  entranceIc: line.entranceIc,
  exitIc: line.exitIc,
  grossFare: line.grossFare,
  etcDiscount: line.etcDiscount,
  fare: line.fare,
  fareAfterRebate: line.fareAfterRebate,
  postpaidFare: line.postpaidFare,
  vehicleType: line.vehicleType,
  vehicleNumber: line.vehicleNumber,
  cardNumber: line.cardNumber,
  status: line.status,
  discountTypes: line.discountTypes,
  memo: memo,
  tags: tags,
);
