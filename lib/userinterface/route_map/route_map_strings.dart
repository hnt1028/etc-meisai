import 'package:etc_meisai/domain/value/route_map_layer_value.dart';

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

  static const layerButton = '地図の表示';
  static const layerSheetTitle = '地図の表示';
  static const layerSaveFailed = '設定を保存できませんでした';

  static String layerTitle(RouteMapLayerValue layer) => switch (layer) {
    RouteMapLayerValue.network => '路線図（すべての路線）',
    RouteMapLayerValue.networkNames => '路線図の路線名',
    RouteMapLayerValue.traveled => '走行した路線図',
    RouteMapLayerValue.markers => 'ICのマーカー（名前つき）',
    RouteMapLayerValue.pending => '確認中の線',
    RouteMapLayerValue.scaleByCount => '走行回数で線の太さを変える',
  };

  static String layerNote(RouteMapLayerValue layer) => switch (layer) {
    RouteMapLayerValue.network => 'すべての路線を、薄い灰色の線で結びます',
    RouteMapLayerValue.networkNames => '地図を拡大したときに、路線の名前を表示します',
    RouteMapLayerValue.traveled => '走行した区間を、路線の色の線で結びます',
    RouteMapLayerValue.markers => 'IC・料金所の印と名前を表示します。タップで位置を指定できます',
    RouteMapLayerValue.pending => '確認中の明細行の線（破線）を表示します',
    RouteMapLayerValue.scaleByCount => '何度も走った区間ほど、太い線で描きます',
  };

  static const loadFailed = '読み込めませんでした';
  static const retry = '再読み込み';
  static const saveFailed = '登録できませんでした';
  static const deleteFailed = '解除できませんでした';
}
