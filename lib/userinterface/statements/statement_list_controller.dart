import 'package:etc_meisai/application/dto/statement_list_dto.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The filter the user chose. A null field means "not filtered".
class StatementFilterState {
  const StatementFilterState({
    this.from,
    this.to,
    this.vehicleNumber,
    this.cardNumberSuffix,
  });

  final DateTime? from;
  final DateTime? to;
  final int? vehicleNumber;
  final String? cardNumberSuffix;

  /// True when at least one condition is set.
  bool get isActive =>
      from != null ||
      to != null ||
      vehicleNumber != null ||
      cardNumberSuffix != null;
}

final statementFilterProvider =
    NotifierProvider<StatementFilterController, StatementFilterState>(
      StatementFilterController.new,
    );

/// OP-2 and OP-3 of SCR-002.
class StatementFilterController extends Notifier<StatementFilterState> {
  @override
  StatementFilterState build() => const StatementFilterState();

  void setPeriod(DateTime from, DateTime to) => state = StatementFilterState(
    from: from,
    to: to,
    vehicleNumber: state.vehicleNumber,
    cardNumberSuffix: state.cardNumberSuffix,
  );

  void setVehicleNumber(int? vehicleNumber) => state = StatementFilterState(
    from: state.from,
    to: state.to,
    vehicleNumber: vehicleNumber,
    cardNumberSuffix: state.cardNumberSuffix,
  );

  void setCardNumberSuffix(String? cardNumberSuffix) =>
      state = StatementFilterState(
        from: state.from,
        to: state.to,
        vehicleNumber: state.vehicleNumber,
        cardNumberSuffix: cardNumberSuffix,
      );

  /// OP-3: removes every condition.
  void clear() => state = const StatementFilterState();
}

/// How the statement lines are shown.
enum StatementListMode { list, timeline }

final statementListModeProvider =
    NotifierProvider<StatementListModeController, StatementListMode>(
      StatementListModeController.new,
    );

/// OP-6 of SCR-002.
class StatementListModeController extends Notifier<StatementListMode> {
  @override
  StatementListMode build() => StatementListMode.list;

  void select(StatementListMode mode) => state = mode;
}

final timelineDayProvider = NotifierProvider<TimelineDayController, DateTime?>(
  TimelineDayController.new,
);

/// OP-7 of SCR-002: the day the timeline shows. Null means the newest day that
/// has statement lines.
class TimelineDayController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime day) => state = DateTime(day.year, day.month, day.day);
}

/// OP-1: the statement lines for the current filter. It is read again when the
/// filter or the stored data changes.
final statementListProvider = FutureProvider<StatementListDTO>((ref) {
  ref.watch(dataRevisionProvider);
  final filter = ref.watch(statementFilterProvider);
  return ref
      .read(listStatementLinesUCProvider)
      .execute(
        from: filter.from,
        to: filter.to,
        vehicleNumber: filter.vehicleNumber,
        cardNumberSuffix: filter.cardNumberSuffix,
      );
}, retry: (_, _) => null);
