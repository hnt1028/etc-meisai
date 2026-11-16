import 'package:etc_meisai/userinterface/aggregation/aggregation_controller.dart';
import 'package:etc_meisai/userinterface/common/format.dart';

/// Every text of the aggregation screen.
/// Design: docs/systems/screens/SCR-006-aggregation.md
abstract final class AggregationStrings {
  static const title = '集計';
  static const filterTitle = '絞り込み';

  static const loadFailed = '読み込めませんでした';
  static const retry = '再読み込み';

  static String summary(int count, int fare, int discount) =>
      '回数 ${countText(count)}　利用額 ${formatYen(fare)}　'
      '割引額 ${formatYen(discount)}';

  static const operatorNote = '路線名からの推定です';

  static String kind(AggregationKind kind) => switch (kind) {
    AggregationKind.period => '期間',
    AggregationKind.operator => '事業者',
    AggregationKind.route => '路線',
    AggregationKind.ic => 'IC',
    AggregationKind.hour => '時間帯',
    AggregationKind.discount => '割引',
  };

  static String unit(AggregationUnit unit) => switch (unit) {
    AggregationUnit.week => '週',
    AggregationUnit.month => '月',
    AggregationUnit.year => '年',
  };

  static String display(AggregationDisplay display) => switch (display) {
    AggregationDisplay.table => '表',
    AggregationDisplay.graph => 'グラフ',
  };

  static String metric(AggregationMetric metric) => switch (metric) {
    AggregationMetric.count => '回数',
    AggregationMetric.fare => '利用額',
    AggregationMetric.discount => '割引額',
  };

  static String countText(int count) => '$count回';

  /// The text of a value: a count in times, an amount in yen.
  static String value(AggregationMetric metric, int value) =>
      metric == AggregationMetric.count ? countText(value) : formatYen(value);

  /// The name of a row as shown. [label] is the one of the DTO.
  static String rowLabel(
    AggregationKind kind,
    AggregationUnit unit,
    String label,
  ) {
    if (kind == AggregationKind.hour) return '$label時';
    if (kind != AggregationKind.period) return label;
    return switch (unit) {
      AggregationUnit.week => '$label〜',
      AggregationUnit.month => label,
      AggregationUnit.year => '$label年',
    };
  }
}
