import 'dart:math' as math;

import 'package:etc_meisai/application/dto/aggregation_dto.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_controller.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_strings.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One slice of the pie: a name and a value that is more than 0.
class PieSlice {
  const PieSlice(this.label, this.value, {this.isOther = false});

  final String label;
  final int value;

  /// True for the slice that gathers the routes or ICs outside the top 10.
  final bool isOther;
}

/// The slices of [kind] for [metric]. Rows with the value 0 are left out. The
/// routes and the ICs get a slice for the rest of them (docs/aggregation.md).
List<PieSlice> pieSlicesOf(
  AggregationDTO data,
  AggregationKind kind,
  AggregationMetric metric,
) {
  final rows = rowsOf(data, kind, AggregationUnit.month);
  final other = switch (kind) {
    AggregationKind.route => data.routesOtherCount,
    AggregationKind.ic => data.icsOtherCount,
    _ => 0,
  };
  return [
    for (final row in rows)
      if ((metric.of(row) ?? 0) > 0) PieSlice(row.label, metric.of(row)!),
    if (other > 0 && metric == AggregationMetric.count)
      PieSlice(AggregationStrings.other, other, isOther: true),
  ];
}

/// The rows as a pie chart with a legend (name, value and share).
class AggregationPie extends StatelessWidget {
  const AggregationPie({super.key, required this.slices, required this.metric});

  final List<PieSlice> slices;
  final AggregationMetric metric;

  /// The colors of the slices: the hue of the theme color, turned round the
  /// circle. The slice for the rest is grey.
  static List<Color> colorsOf(ColorScheme scheme, List<PieSlice> slices) {
    final base = HSLColor.fromColor(scheme.primary);
    final colored = slices.where((s) => !s.isOther).length;
    var index = 0;
    return [
      for (final slice in slices)
        slice.isOther
            ? scheme.outline
            : base
                  .withHue(
                    (base.hue + 360 * index++ / math.max(colored, 1)) % 360,
                  )
                  .toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (slices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(AggregationStrings.noPieValues),
      );
    }
    final total = slices.fold<int>(0, (sum, s) => sum + s.value);
    final colors = colorsOf(scheme, slices);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  for (var i = 0; i < slices.length; i++)
                    PieChartSectionData(
                      value: slices[i].value.toDouble(),
                      color: colors[i],
                      radius: 70,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < slices.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    key: ValueKey('legend-color-$i'),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(slices[i].label, style: textTheme.bodyMedium),
                  ),
                  Text(
                    AggregationStrings.value(metric, slices[i].value),
                    style: textTheme.bodyMedium,
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      AggregationStrings.percent(slices[i].value, total),
                      textAlign: TextAlign.end,
                      style: textTheme.bodyMedium,
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
