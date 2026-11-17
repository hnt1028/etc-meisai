import 'package:etc_meisai/application/dto/entrance_candidates_dto.dart';
import 'package:etc_meisai/application/dto/line_route_dto.dart';
import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/statements/line_route_map.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_providers.dart';
import 'package:etc_meisai/userinterface/statements/entrance_dialogs.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/vehicle_number_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SCR-003: shows every field of one statement line. [line] is null when the
/// screen was opened without a statement line (ER-1).
class StatementDetailScreen extends ConsumerStatefulWidget {
  const StatementDetailScreen({super.key, required this.line});

  final StatementLineDTO? line;

  @override
  ConsumerState<StatementDetailScreen> createState() =>
      _StatementDetailScreenState();
}

class _StatementDetailScreenState extends ConsumerState<StatementDetailScreen> {
  /// The line shown. It changes when the user saves a vehicle number (OP-3).
  late StatementLineDTO? _line = widget.line;

  /// OP-3: asks for the vehicle number, saves it, and shows it.
  Future<void> _enterVehicleNumber() async {
    final line = _line;
    final id = line?.id;
    if (line == null || id == null) return;
    final number = await showVehicleNumberDialog(context);
    if (number == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(saveVehicleNumberUCProvider)
          .execute(id: id, vehicleNumber: number);
    } catch (_) {
      // The details are not shown: they could contain personal data.
      messenger.showSnackBar(
        const SnackBar(
          content: Text(StatementDetailStrings.saveVehicleNumberFailed),
        ),
      );
      return;
    }
    // The list, the map and the aggregation read the lines again.
    ref.read(dataRevisionProvider.notifier).changed();
    // The screen shows the line again when the lines have been read again.
  }

  /// OP-4: asks for the entrance date and time, saves it, and shows it.
  Future<void> _enterEntranceAt() async {
    final line = _line;
    final id = line?.id;
    if (line == null || id == null) return;
    // The pickers start with the estimate. A failure to estimate must not stop
    // the user: they start with the exit then.
    DateTime? estimate;
    try {
      estimate = await ref.read(estimateEntranceAtUCProvider).execute(line);
    } catch (_) {
      estimate = null;
    }
    if (!mounted) return;
    final entranceAt = await showEntranceAtDialog(
      context,
      exitAt: line.exitAt,
      estimate: estimate,
    );
    if (entranceAt == null || !mounted) return;
    await _saveEntrance(
      () => ref
          .read(saveEntranceUCProvider)
          .execute(id: id, entranceAt: entranceAt),
    );
  }

  /// OP-5: asks for the entrance IC, saves it, and shows it.
  Future<void> _enterEntranceIc() async {
    final line = _line;
    final id = line?.id;
    if (line == null || id == null) return;
    // When the choices cannot be read, the user can still type the name.
    var candidates = const EntranceCandidatesDTO(used: [], sameRoute: []);
    try {
      candidates = await ref
          .read(listEntranceCandidatesUCProvider)
          .execute(line);
    } catch (_) {}
    if (!mounted) return;
    final entranceIc = await showEntranceIcDialog(
      context,
      candidates: candidates,
    );
    if (entranceIc == null || !mounted) return;
    await _saveEntrance(
      () => ref
          .read(saveEntranceUCProvider)
          .execute(id: id, entranceIc: entranceIc),
    );
  }

  /// Runs [save], and then makes the other screens, and this one, read the
  /// lines again. A failure is shown as a message, without details.
  Future<void> _saveEntrance(Future<void> Function() save) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await save();
    } on ArgumentError {
      // The only input the dialogs let through that the use case refuses is an
      // entrance time on the exit day that is after the exit (ER-4).
      messenger.showSnackBar(
        const SnackBar(content: Text(StatementDetailStrings.entranceAfterExit)),
      );
      return;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(StatementDetailStrings.saveVehicleNumberFailed),
        ),
      );
      return;
    }
    ref.read(dataRevisionProvider.notifier).changed();
  }

  /// A field the CSV left blank: a dash, and a button to enter it when the
  /// line is stored.
  Widget _blankItem(
    String label,
    StatementLineDTO line,
    Key buttonKey,
    VoidCallback onPressed,
  ) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(StatementDetailStrings.blank),
          if (line.id != null)
            TextButton(
              key: buttonKey,
              onPressed: onPressed,
              child: const Text(StatementDetailStrings.vehicleNumberEnter),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // When the lines are read again (after a save), show the fresh line: its
    // route names are made again from the new entrance.
    ref.listen(statementListProvider, (_, next) {
      final id = _line?.id;
      if (id == null || !next.hasValue) return;
      for (final fresh in next.value!.lines) {
        if (fresh.id == id && mounted) {
          setState(() => _line = fresh);
          return;
        }
      }
    });
    final line = _line;
    return Scaffold(
      appBar: AppBar(title: const Text(StatementDetailStrings.title)),
      body: line == null
          ? const Center(child: Text(StatementDetailStrings.notFound))
          : ListView(
              children: [
                LineRouteMap(line: line),
                if (line.entranceAt == null)
                  _blankItem(
                    StatementDetailStrings.entranceAt,
                    line,
                    const ValueKey('enter-entrance-at'),
                    _enterEntranceAt,
                  )
                else
                  _item(
                    StatementDetailStrings.entranceAt,
                    formatDateTime(line.entranceAt!),
                  ),
                _item(
                  StatementDetailStrings.exitAt,
                  formatDateTime(line.exitAt),
                ),
                if (line.entranceIc == null)
                  _blankItem(
                    StatementDetailStrings.entranceIc,
                    line,
                    const ValueKey('enter-entrance-ic'),
                    _enterEntranceIc,
                  )
                else
                  _item(StatementDetailStrings.entranceIc, line.entranceIc!),
                _item(StatementDetailStrings.exitIc, line.exitIc),
                _item(
                  StatementDetailStrings.routeNames,
                  line.routeNames.isEmpty
                      ? StatementDetailStrings.blank
                      : line.routeNames.join('・'),
                ),
                _item(
                  StatementDetailStrings.distance,
                  _distance(ref.watch(lineRouteProvider(line))),
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
                _item(StatementDetailStrings.vehicleType, line.vehicleTypeName),
                if (line.vehicleNumber == null)
                  _blankItem(
                    StatementDetailStrings.vehicleNumber,
                    line,
                    const ValueKey('enter-vehicle-number'),
                    _enterVehicleNumber,
                  )
                else
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

  /// "-" while the route is read, when it failed, and when the distance is not
  /// known.
  static String _distance(AsyncValue<LineRouteDTO> route) {
    final meters = route.value?.meters;
    return meters == null ? StatementDetailStrings.blank : formatKm(meters);
  }

  /// A blank amount (null) means that no discount applied.
  static String _yen(int? yen) =>
      yen == null ? StatementDetailStrings.blank : formatYen(yen);

  static Widget _item(String label, String value) =>
      ListTile(dense: true, title: Text(label), trailing: Text(value));
}
