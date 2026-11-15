import 'package:etc_meisai/userinterface/common/format.dart';

/// Every text of the statement list screen.
/// Design: docs/systems/screens/SCR-002-statement-list.md
abstract final class StatementListStrings {
  static const title = '利用明細一覧';

  static const periodLabel = '期間';
  static const periodNone = '指定なし';
  static const vehicleNumberLabel = '車両番号';
  static const cardNumberLabel = 'ETCカード番号';
  static const choiceAll = 'すべて';
  static const clearFilter = '絞り込みを解除';

  /// Shows only the last 4 characters of the card number.
  static String cardNumberChoice(String suffix) => '**** $suffix';

  static String period(DateTime from, DateTime to) =>
      '${formatDate(from)} 〜 ${formatDate(to)}';

  static String totalFare(int yen) => '合計金額 ${formatYen(yen)}';
  static String totalBreakdown(int fareAfterRebate, int postpaidFare) =>
      '還元額適用料金 ${formatYen(fareAfterRebate)} / '
      '後納料金 ${formatYen(postpaidFare)}';

  static const blank = '-';
  static String route(String? entranceIc, String exitIc) =>
      '${entranceIc ?? blank} → $exitIc';
  static String times(DateTime? entranceAt, DateTime exitAt) =>
      '${entranceAt == null ? blank : formatDateTime(entranceAt)} → '
      '${formatDateTime(exitAt)}';
  static const pending = '確認中';

  static const emptyNoData = '取り込んだ明細行がありません';
  static const emptyNoMatch = '条件に合う明細行がありません';

  static const loadFailed = '読み込めませんでした';
  static const retry = '再読み込み';
}
