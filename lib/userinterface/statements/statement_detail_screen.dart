import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/statements/line_route_map.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:flutter/material.dart';

/// SCR-003: shows every field of one statement line. [line] is null when the
/// screen was opened without a statement line (ER-1).
class StatementDetailScreen extends StatelessWidget {
  const StatementDetailScreen({super.key, required this.line});

  final StatementLineDTO? line;

  @override
  Widget build(BuildContext context) {
    final line = this.line;
    return Scaffold(
      appBar: AppBar(title: const Text(StatementDetailStrings.title)),
      body: line == null
          ? const Center(child: Text(StatementDetailStrings.notFound))
          : ListView(
              children: [
                LineRouteMap(line: line),
                _item(
                  StatementDetailStrings.entranceAt,
                  line.entranceAt == null
                      ? StatementDetailStrings.blank
                      : formatDateTime(line.entranceAt!),
                ),
                _item(
                  StatementDetailStrings.exitAt,
                  formatDateTime(line.exitAt),
                ),
                _item(
                  StatementDetailStrings.entranceIc,
                  line.entranceIc ?? StatementDetailStrings.blank,
                ),
                _item(StatementDetailStrings.exitIc, line.exitIc),
                _item(
                  StatementDetailStrings.routeNames,
                  line.routeNames.isEmpty
                      ? StatementDetailStrings.blank
                      : line.routeNames.join('・'),
                ),
                _item(StatementDetailStrings.grossFare, _yen(line.grossFare)),
                _item(
                  StatementDetailStrings.etcDiscount,
                  _yen(line.etcDiscount),
                ),
                _item(StatementDetailStrings.fare, formatYen(line.fare)),
                _item(
                  StatementDetailStrings.fareAfterRebate,
                  formatYen(line.fareAfterRebate),
                ),
                _item(
                  StatementDetailStrings.postpaidFare,
                  formatYen(line.postpaidFare),
                ),
                _item(
                  StatementDetailStrings.vehicleType,
                  line.vehicleType.label,
                ),
                _item(
                  StatementDetailStrings.vehicleNumber,
                  '${line.vehicleNumber}',
                ),
                _item(
                  StatementDetailStrings.cardNumber,
                  StatementDetailStrings.cardNumberValue(line.cardNumberSuffix),
                ),
                _item(
                  StatementDetailStrings.status,
                  line.status == ConfirmationStatusValue.pending
                      ? StatementDetailStrings.pending
                      : StatementDetailStrings.confirmed,
                ),
                _item(
                  StatementDetailStrings.discountTypes,
                  line.discountTypes.isEmpty
                      ? StatementDetailStrings.none
                      : line.discountTypes.join('・'),
                ),
              ],
            ),
    );
  }

  /// A blank amount (null) means that no discount applied.
  static String _yen(int? yen) =>
      yen == null ? StatementDetailStrings.blank : formatYen(yen);

  static Widget _item(String label, String value) =>
      ListTile(dense: true, title: Text(label), trailing: Text(value));
}
