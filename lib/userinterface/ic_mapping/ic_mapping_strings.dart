import 'package:etc_meisai/domain/value/ic_kind_value.dart';

/// Every text of the IC mapping screen.
/// Design: docs/systems/screens/SCR-004-ic-mapping.md
abstract final class IcMappingStrings {
  static const title = 'ICの対応づけ';

  static const unresolvedSection = '未対応のIC';
  static const registeredSection = '登録済み';

  static String ambiguous(int lineCount) => '複数の候補があります（$lineCount件の明細行）';
  static String unknown(int lineCount) => '見つかりません（$lineCount件の明細行）';

  static const noUnresolved = '対応づけが必要なICはありません';
  static const noRegistered = '登録した対応づけはありません';

  static String registeredLine(String icName, String pointName) =>
      '$icName → $pointName';
  static const pointMissing = '地点が見つかりません';
  static const unlink = '解除';

  static String pickerTitle(String icName) => '地点を選ぶ（$icName）';
  static const searchHint = '地点の名前で探す';
  static const noResult = '見つかりませんでした';

  /// The kind, the routes and the position of an IC point.
  static String pointDetail({
    required IcKindValue kind,
    required List<String> routeNames,
    required double latitude,
    required double longitude,
  }) {
    final routes = routeNames.isEmpty ? '' : '・${routeNames.join('・')}';
    return '${kind.label}$routes・'
        '北緯${latitude.toStringAsFixed(3)} 東経${longitude.toStringAsFixed(3)}';
  }

  static const loadFailed = '読み込めませんでした';
  static const retry = '再読み込み';
  static const searchFailed = '探せませんでした';
  static const saveFailed = '登録できませんでした';
  static const deleteFailed = '解除できませんでした';
}
