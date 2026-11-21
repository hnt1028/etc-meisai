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

  static String coverageSummary(int covered, int total) =>
      '走った路線: $covered / $total 路線';
  static const coverageNote =
      '路線の区間（ICの間）のうち、走った区間の道のりの割合です。走った経路は、入口から出口までの最短の経路と見なします';
  static const coverageNone = '走った路線がありません';

  /// [tenths] is the share in tenths of a percent: 123 is 12.3%.
  static String coveragePercent(int tenths) =>
      '${tenths ~/ 10}.${tenths % 10}%';
  static String coverageDistance(String driven, String total) =>
      '$driven / $total';

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
    AggregationKind.coverage => '走破率',
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
