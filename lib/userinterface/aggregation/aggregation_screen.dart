import 'package:etc_meisai/application/dto/aggregation_dto.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_controller.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_pie.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_strings.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_views.dart';
import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/statements/statement_filter_bar.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SCR-006: aggregates the statement lines and shows them as a table or as
/// bars.
class AggregationScreen extends ConsumerWidget {
  const AggregationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregation = ref.watch(aggregationProvider);
    final filter = ref.watch(statementFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AggregationStrings.title)),
      body: aggregation.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MessageText(AggregationStrings.loadFailed, isError: true),
              TextButton(
                onPressed: () => ref.invalidate(aggregationProvider),
                child: const Text(AggregationStrings.retry),
              ),
            ],
          ),
        ),
        data: (data) => ListView(
          children: [
            if (aggregation.isLoading) const LinearProgressIndicator(),
            ExpansionTile(
              title: const Text(AggregationStrings.filterTitle),
              shape: const Border(),
              collapsedShape: const Border(),
              children: [
                StatementFilterBar(
                  filter: filter,
                  vehicleNumberChoices: data.vehicleNumberChoices,
                  cardNumberChoices: data.cardNumberChoices,
                  tagChoices: data.tagChoices,
                ),
              ],
            ),
            if (data.summary.lineCount == 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  filter.isActive
                      ? StatementListStrings.emptyNoMatch
                      : StatementListStrings.emptyNoData,
                ),
              )
            else
              _Body(data: data),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});

  final AggregationDTO data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(aggregationViewProvider);
    final controller = ref.read(aggregationViewProvider.notifier);
    final rows = rowsOf(data, view.kind, view.unit);
    final metrics = metricsOf(view.kind);
    final summary = data.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card.filled(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              AggregationStrings.summary(
                summary.lineCount,
                summary.fareTotal,
                summary.discountTotal,
                summary.distanceTotal,
              ),
            ),
          ),
        ),
        if (summary.distanceUnknownCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              AggregationStrings.distanceUnknown(summary.distanceUnknownCount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final kind in AggregationKind.values)
                ChoiceChip(
                  label: Text(AggregationStrings.kind(kind)),
                  selected: view.kind == kind,
                  onSelected: (_) => controller.setKind(kind),
                ),
            ],
          ),
        ),
        if (view.kind == AggregationKind.coverage)
          _CoverageList(data: data)
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (view.kind == AggregationKind.period)
                  SegmentedButton<AggregationUnit>(
                    segments: [
                      for (final unit in AggregationUnit.values)
                        ButtonSegment(
                          value: unit,
                          label: Text(AggregationStrings.unit(unit)),
                        ),
                    ],
                    selected: {view.unit},
                    onSelectionChanged: (s) => controller.setUnit(s.single),
                  ),
                SegmentedButton<AggregationDisplay>(
                  segments: [
                    for (final display in AggregationDisplay.values)
                      ButtonSegment(
                        value: display,
                        label: Text(AggregationStrings.display(display)),
                      ),
                  ],
                  selected: {view.display},
                  onSelectionChanged: (s) => controller.setDisplay(s.single),
                ),
                if (view.display == AggregationDisplay.graph &&
                    metrics.length > 1)
                  SegmentedButton<AggregationMetric>(
                    segments: [
                      for (final metric in metrics)
                        ButtonSegment(
                          value: metric,
                          label: Text(AggregationStrings.metric(metric)),
                        ),
                    ],
                    selected: {view.metric},
                    onSelectionChanged: (s) => controller.setMetric(s.single),
                  ),
              ],
            ),
          ),
          if (view.kind == AggregationKind.operator)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                AggregationStrings.operatorNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (view.kind == AggregationKind.tag)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                AggregationStrings.tagNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (_showsDistance(view, metrics))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                AggregationStrings.distanceNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          if (view.display == AggregationDisplay.table)
            AggregationTable(rows: rows, kind: view.kind, unit: view.unit)
          else if (view.kind == AggregationKind.period ||
              view.kind == AggregationKind.hour)
            AggregationBars(
              rows: rows,
              kind: view.kind,
              unit: view.unit,
              metric: view.metric,
            )
          else
            AggregationPie(
              slices: pieSlicesOf(data, view.kind, view.metric),
              metric: view.metric,
            ),
        ],
      ],
    );
  }
}

/// The note about the distance is shown where the distance is: in a table with
/// a distance column, and in a graph of the distance.
bool _showsDistance(
  AggregationViewState view,
  List<AggregationMetric> metrics,
) =>
    metrics.contains(AggregationMetric.distance) &&
    (view.display == AggregationDisplay.table ||
        view.metric == AggregationMetric.distance);

/// The roads the user has driven, with how much of each (the kind "走破率").
class _CoverageList extends StatelessWidget {
  const _CoverageList({required this.data});

  final AggregationDTO data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            AggregationStrings.coverageSummary(
              data.coverage.length,
              data.coverageRouteCount,
            ),
            key: const ValueKey('coverage-summary'),
            style: theme.textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            AggregationStrings.coverageNote,
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (data.coverage.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(AggregationStrings.coverageNone),
          ),
        for (final row in data.coverage)
          Padding(
            key: ValueKey('coverage-${row.routeName}'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(row.routeName)),
                    Text(
                      AggregationStrings.coveragePercent(coverageTenths(row)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: coverageTenths(row) / 1000,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                Text(
                  AggregationStrings.coverageDistance(
                    formatKm(row.drivenMeters),
                    formatKm(row.totalMeters),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
