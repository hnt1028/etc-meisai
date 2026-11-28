import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/ic_lookup.dart';
import 'package:etc_meisai/application/usecase/statements/vehicle_type_name.dart';
import 'package:etc_meisai/domain/entity/vehicle_type_division_entity.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';

/// The parts that the statement list (PRC-004) and the route map (PRC-009)
/// share: the filter, its choices and the DTO of a statement line.

/// The last 4 characters. A shorter number is returned as it is.
String cardNumberSuffixOf(String cardNumber) => cardNumber.length <= 4
    ? cardNumber
    : cardNumber.substring(cardNumber.length - 4);

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

/// The vehicle numbers of [all], the smallest first, without duplicates.
List<int> vehicleNumberChoicesOf(List<StatementLineEntity> all) =>
    {for (final line in all) ?line.vehicleNumber}.toList()..sort();

/// The last 4 characters of the card numbers of [all], without duplicates.
List<String> cardNumberChoicesOf(List<StatementLineEntity> all) =>
    {for (final line in all) cardNumberSuffixOf(line.cardNumber)}.toList()
      ..sort();

/// The lines of [all] that meet every condition that is not null, the newest
/// exit first. [from] and [to] are dates (the time is ignored) and are
/// included in the period.
/// Every tag of [all], sorted.
List<String> tagChoicesOf(List<StatementLineEntity> all) =>
    {for (final line in all) ...line.tags}.toList()..sort();

List<StatementLineEntity> filterStatementLines(
  List<StatementLineEntity> all, {
  DateTime? from,
  DateTime? to,
  int? vehicleNumber,
  String? cardNumberSuffix,
  String? tag,
}) {
  final fromDay = from == null ? null : _day(from);
  final toDay = to == null ? null : _day(to);
  final matched = all.where((line) {
    final exitDay = _day(line.exitAt);
    if (fromDay != null && exitDay.isBefore(fromDay)) return false;
    if (toDay != null && exitDay.isAfter(toDay)) return false;
    if (vehicleNumber != null && line.vehicleNumber != vehicleNumber) {
      return false;
    }
    if (cardNumberSuffix != null &&
        cardNumberSuffixOf(line.cardNumber) != cardNumberSuffix) {
      return false;
    }
    if (tag != null && !line.tags.contains(tag)) return false;
    return true;
  }).toList();
  // List.sort is not stable, so ties keep their stored order by index.
  final indexed = matched.asMap().entries.toList()
    ..sort((a, b) {
      final byExit = b.value.exitAt.compareTo(a.value.exitAt);
      return byExit != 0 ? byExit : a.key.compareTo(b.key);
    });
  return [for (final e in indexed) e.value];
}

/// Makes the DTO of a statement line, with its route names and the name of its
/// vehicle type.
StatementLineDTO toStatementLineDTO(
  StatementLineEntity line,
  IcLookup lookup,
  List<VehicleTypeDivisionEntity> divisions,
) => StatementLineDTO(
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
  vehicleTypeName: vehicleTypeNameOf(
    line.vehicleType,
    lookup.routeNamesOf(line.entranceIc, line.exitIc),
    divisions,
  ),
  vehicleNumber: line.vehicleNumber,
  cardNumberSuffix: cardNumberSuffixOf(line.cardNumber),
  status: line.status,
  discountTypes: List.unmodifiable(line.discountTypes),
  routeNames: lookup.routeNamesOf(line.entranceIc, line.exitIc),
  memo: line.memo,
  tags: List.unmodifiable(line.tags),
);
