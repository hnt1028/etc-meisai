import 'package:etc_meisai/application/dto/aggregation_dto.dart';
import 'package:etc_meisai/application/dto/aggregation_row_dto.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_providers.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OP-1 of SCR-006: the aggregation for the current filter. It is read again
/// when the filter or the stored data changes.
final aggregationProvider = FutureProvider<AggregationDTO>((ref) {
  ref.watch(dataRevisionProvider);
  final filter = ref.watch(statementFilterProvider);
  return ref
      .read(aggregateStatementsUCProvider)
      .execute(
        from: filter.from,
        to: filter.to,
        vehicleNumber: filter.vehicleNumber,
        cardNumberSuffix: filter.cardNumberSuffix,
      );
}, retry: (_, _) => null);

/// What is aggregated.
enum AggregationKind { period, operator, route, ic, hour, discount }

/// The unit of the period aggregation.
enum AggregationUnit { week, month, year }

enum AggregationDisplay { table, graph }

/// A value of a row.
enum AggregationMetric {
  count,
  fare,
  discount;

  /// The value of [row], or null when the aggregation does not give it.
  int? of(AggregationRowDTO row) => switch (this) {
    count => row.count,
    fare => row.fare,
    discount => row.discount,
  };
}

/// The values each kind gives (docs/aggregation.md).
List<AggregationMetric> metricsOf(AggregationKind kind) => switch (kind) {
  AggregationKind.route || AggregationKind.ic => [AggregationMetric.count],
  AggregationKind.discount => [
    AggregationMetric.count,
    AggregationMetric.discount,
  ],
  _ => AggregationMetric.values,
};

/// The rows to show for [kind] (and [unit] for a period).
List<AggregationRowDTO> rowsOf(
  AggregationDTO data,
  AggregationKind kind,
  AggregationUnit unit,
) => switch (kind) {
  AggregationKind.period => switch (unit) {
    AggregationUnit.week => data.weeks,
    AggregationUnit.month => data.months,
    AggregationUnit.year => data.years,
  },
  AggregationKind.operator => data.operators,
  AggregationKind.route => data.routes,
  AggregationKind.ic => data.ics,
  AggregationKind.hour => data.hours,
  AggregationKind.discount => data.discountTypes,
};

/// What the user chose on the screen (OP-3 to OP-6).
class AggregationViewState {
  const AggregationViewState({
    this.kind = AggregationKind.period,
    this.unit = AggregationUnit.month,
    this.display = AggregationDisplay.table,
    this.metric = AggregationMetric.fare,
  });

  final AggregationKind kind;
  final AggregationUnit unit;
  final AggregationDisplay display;
  final AggregationMetric metric;

  AggregationViewState copyWith({
    AggregationKind? kind,
    AggregationUnit? unit,
    AggregationDisplay? display,
    AggregationMetric? metric,
  }) => AggregationViewState(
    kind: kind ?? this.kind,
    unit: unit ?? this.unit,
    display: display ?? this.display,
    metric: metric ?? this.metric,
  );
}

final aggregationViewProvider =
    NotifierProvider<AggregationViewController, AggregationViewState>(
      AggregationViewController.new,
    );

class AggregationViewController extends Notifier<AggregationViewState> {
  @override
  AggregationViewState build() => const AggregationViewState();

  /// OP-3. The value becomes the count when the kind does not give it.
  void setKind(AggregationKind kind) => state = state.copyWith(
    kind: kind,
    metric: metricsOf(kind).contains(state.metric)
        ? state.metric
        : AggregationMetric.count,
  );

  void setUnit(AggregationUnit unit) => state = state.copyWith(unit: unit);

  void setDisplay(AggregationDisplay display) =>
      state = state.copyWith(display: display);

  void setMetric(AggregationMetric metric) =>
      state = state.copyWith(metric: metric);
}
