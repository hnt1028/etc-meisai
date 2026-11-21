import 'package:etc_meisai/userinterface/aggregation/aggregation_controller.dart';
import 'package:etc_meisai/userinterface/common/format.dart';

/// Every text of the aggregation screen.
/// Design: docs/systems/screens/SCR-006-aggregation.md
abstract final class AggregationStrings {
  static const title = '集計';
  static const filterTitle = '絞り込み';

  static const loadFailed = '読み込めませんでした';
  static const retry = '再読み込み';

  static String summary(int count, int fare, int discount, int meters) =>
      '回数 ${countText(count)}　利用額 ${formatYen(fare)}　'
      '割引額 ${formatYen(discount)}　距離 ${formatKm(meters)}';

  /// Under the totals, when some lines have no distance.
  static String distanceUnknown(int count) =>
      '距離が分からない明細行: $count件（距離の合計に含みません）';

  static const distanceNote = '距離は道路に沿った道のりの推定です';

  static const operatorNote = '路線名からの推定です';

  static const tagNote = 'タグが複数ある明細行は、それぞれのタグに数えます（合計は、全体と一致しません）';

  /// The slice of the pie for the routes and ICs outside the top 10.
  static const other = 'その他';
  static const noPieValues = '表示できる値がありません';

  /// The share of [value] in [total], with one decimal place: 33.3%.
  static String percent(int value, int total) =>
      '${(value * 100 / total).toStringAsFixed(1)}%';

  static String kind(AggregationKind kind) => switch (kind) {
    AggregationKind.period => '期間',
    AggregationKind.operator => '事業者',
    AggregationKind.tag => 'タグ',
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
    AggregationMetric.distance => '距離',
  };

  static String countText(int count) => '$count回';

  /// The text of a value: a count in times, an amount in yen.
  static String value(AggregationMetric metric, int value) => switch (metric) {
    AggregationMetric.count => countText(value),
    AggregationMetric.distance => formatKm(value),
    _ => formatYen(value),
  };

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
