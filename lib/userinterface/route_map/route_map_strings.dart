/// Every text of the route map screen.
/// Design: docs/systems/screens/SCR-005-route-map.md
abstract final class RouteMapStrings {
  static const title = 'ルートマップ';
  static const filterTitle = '絞り込み';

  static String unlocatedBanner(int icCount, int lineCount) =>
      '位置不明のICが $icCount 件あります（$lineCount 件の明細行は描けません）';
  static const specifyPosition = '位置を指定';

  static String picking(String icName) => '「$icName」の位置を決めます。地図をタップしてください';
  static const register = '位置を登録';
  static const cancel = 'キャンセル';

  /// The label of a marker. A borrowed position is marked as approximate.
  static String markerLabel(String icName, {required bool approximate}) =>
      approximate ? '$icName（近似）' : icName;

  static const unlocatedSheetTitle = '位置不明のIC';
  static String lineCount(int count) => '$count件の明細行';

  static const routeNamesLabel = '路線名';
  static const positionLabel = '位置';
  static const noRouteNames = '-';
  static const positionSpecified = '指定した位置';
  static const positionMaster = 'マスタの位置';
  static const approximate = '（近似）';
  static const respecify = '位置を指定し直す';
  static const unspecify = '指定を解除';

  static const segmentSheetTitle = '重なっている明細行';

  static const attribution = '© OpenStreetMap contributors';

  static const loadFailed = '読み込めませんでした';
  static const retry = '再読み込み';
  static const saveFailed = '登録できませんでした';
  static const deleteFailed = '解除できませんでした';
}
