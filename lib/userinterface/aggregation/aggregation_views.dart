import 'package:etc_meisai/application/dto/aggregation_row_dto.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_controller.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_strings.dart';
import 'package:flutter/material.dart';

/// The rows as a table: the name and every value the kind gives.
class AggregationTable extends StatelessWidget {
  const AggregationTable({
    super.key,
    required this.rows,
    required this.kind,
    required this.unit,
  });

  final List<AggregationRowDTO> rows;
  final AggregationKind kind;
  final AggregationUnit unit;

  /// The name and each value share the width in these proportions.
  static const _nameFlex = 4;
  static const _valueFlex = 3;

  @override
  Widget build(BuildContext context) {
    final metrics = metricsOf(kind);
    final style = Theme.of(context).textTheme.bodyMedium;
    final header = Theme.of(context).textTheme.labelMedium;

    Widget row(String name, List<String> values, TextStyle? textStyle) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: _nameFlex,
              child: Text(name, style: textStyle),
            ),
            for (final value in values)
              Expanded(
                flex: _valueFlex,
                // A long value shrinks, so that the columns fit any width.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(value, style: textStyle),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row('', [
          for (final m in metrics) AggregationStrings.metric(m),
        ], header),
        const Divider(height: 1),
        for (final r in rows) ...[
          row(AggregationStrings.rowLabel(kind, unit, r.label), [
            for (final m in metrics) AggregationStrings.value(m, m.of(r) ?? 0),
          ], style),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

/// The rows as horizontal bars. The longest bar is the largest value.
class AggregationBars extends StatelessWidget {
  const AggregationBars({
    super.key,
    required this.rows,
    required this.kind,
    required this.unit,
    required this.metric,
  });

  final List<AggregationRowDTO> rows;
  final AggregationKind kind;
  final AggregationUnit unit;
  final AggregationMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final values = [for (final r in rows) metric.of(r) ?? 0];
    final largest = values.fold<int>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AggregationStrings.rowLabel(
                            kind,
                            unit,
                            rows[i].label,
                          ),
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        AggregationStrings.value(metric, values[i]),
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 10,
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        key: ValueKey('bar-$i'),
                        widthFactor: largest == 0 ? 0 : values[i] / largest,
                        child: Container(color: scheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
