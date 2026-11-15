import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/dto/statement_list_dto.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';

/// Lists the stored statement lines for the statement list screen.
/// Design: PRC-004.
class ListStatementLinesUC {
  const ListStatementLinesUC({required this.statementLines});

  final StatementLineIF statementLines;

  /// [from] and [to] are dates (the time is ignored) and are included in the
  /// period. A null condition is not used.
  Future<StatementListDTO> execute({
    DateTime? from,
    DateTime? to,
    int? vehicleNumber,
    String? cardNumberSuffix,
  }) async {
    final all = await statementLines.findAll();

    final vehicleNumberChoices = {
      for (final line in all) line.vehicleNumber,
    }.toList()..sort();
    final cardNumberChoices = {
      for (final line in all) _suffix(line.cardNumber),
    }.toList()..sort();

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
          _suffix(line.cardNumber) != cardNumberSuffix) {
        return false;
      }
      return true;
    }).toList();
    // List.sort is not stable, so ties keep their stored order by index.
    final indexed = matched.asMap().entries.toList()
      ..sort((a, b) {
        final byExit = b.value.exitAt.compareTo(a.value.exitAt);
        return byExit != 0 ? byExit : a.key.compareTo(b.key);
      });
    final sorted = [for (final e in indexed) e.value];

    return StatementListDTO(
      lines: [for (final line in sorted) _toDto(line)],
      totalFare: sorted.fold(0, (sum, l) => sum + l.fare),
      totalFareAfterRebate: sorted.fold(0, (sum, l) => sum + l.fareAfterRebate),
      totalPostpaidFare: sorted.fold(0, (sum, l) => sum + l.postpaidFare),
      vehicleNumberChoices: vehicleNumberChoices,
      cardNumberChoices: cardNumberChoices,
    );
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// The last 4 characters. A shorter number is returned as it is.
  static String _suffix(String cardNumber) => cardNumber.length <= 4
      ? cardNumber
      : cardNumber.substring(cardNumber.length - 4);

  static StatementLineDTO _toDto(StatementLineEntity line) => StatementLineDTO(
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
    cardNumberSuffix: _suffix(line.cardNumber),
    status: line.status,
    discountTypes: List.unmodifiable(line.discountTypes),
  );
}
