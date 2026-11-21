/// Every text of the settings screen.
/// Design: docs/systems/screens/SCR-001-settings.md
abstract final class SettingsStrings {
  static const title = '設定';

  static const importSection = '利用明細CSVの取り込み';
  static const importButton = 'CSVを選んで取り込む';

  static String importResult(int added, int overwritten, int ignored) =>
      '追加 $added 件 / 上書き $overwritten 件 / 無視 $ignored 件';

  /// [message] describes the invalid part of the CSV (never personal data).
  static String importFailed(String message) => '取り込めませんでした: $message';
  static const importUnexpected = '取り込み中にエラーが発生しました';

  static const tileCacheSection = '保存した地図';
  static const tileCacheNote = '見た場所の地図を、端末に保存しています。通信できないときも、保存した地図を表示します。';
  static String tileCacheSize(String size) => '保存している地図: $size';
  static const tileCacheLoadFailed = '保存した地図の大きさを調べられませんでした';
  static const tileCacheClear = '保存した地図を消す';
  static const tileCacheClearConfirm =
      '保存した地図をすべて消します。通信できないときは、消した場所の地図が表示できなくなります。（もう一度見ると、保存されます）';
  static const tileCacheClearOk = '消す';
  static const tileCacheCleared = '保存した地図を消しました';
  static const tileCacheClearFailed = '消せませんでした';

  static const operatorColorSection = '地図の線の色';
  static const operatorColorNote = '道路の事業者ごとに、地図の線の色を変えられます。';
  static const operatorColorDefault = '初期値';
  static const operatorColorChanged = '変更済み';
  static const operatorColorWheel = '色環';
  static const operatorColorBrightness = '明るさ';
  static const paletteRed = '赤';
  static const palettePink = 'ピンク';
  static const palettePurple = '紫';
  static const paletteIndigo = '藍';
  static const paletteBlue = '青';
  static const paletteCyan = '水色';
  static const paletteTeal = '青緑';
  static const paletteGreen = '緑';
  static const paletteLime = '黄緑';
  static const paletteYellow = '黄';
  static const paletteOrange = '橙';
  static const paletteBrown = '茶';
  static const paletteGrey = '灰';
  static const paletteBlack = '黒';
  static const operatorColorCancel = 'キャンセル';
  static const operatorColorReset = '初期値に戻す';
  static const operatorColorSave = '保存';
  static const operatorColorResetAll = 'すべての色を初期値に戻す';
  static const operatorColorLoadFailed = '線の色を読み込めませんでした';
  static const operatorColorSaveFailed = '保存できませんでした';

  static const backupSection = 'データのバックアップ';
  static const exportButton = 'データを書き出す';
  static const exportNote = '書き出したファイルには、車両番号とETCカード番号が含まれます。保管に注意してください。';
  static const restoreButton = 'データを読み込む（すべて置き換え）';
  static const restoreConfirmMessage =
      '読み込むファイルの内容で、いまのすべてのデータ（明細行・ICの対応づけ・位置の指定・線の色）を置き換えます。'
      'いまのデータはすべて消え、元に戻せません。';
  static const restoreConfirmOk = '置き換える';

  static String _counts(int lines, int mappings, int positions) =>
      '明細行 $lines 件 / 対応づけ $mappings 件 / 位置の指定 $positions 件';

  static String exported(int lines, int mappings, int positions) =>
      '書き出しました（${_counts(lines, mappings, positions)}）';
  static String restored(int lines, int mappings, int positions) =>
      '読み込みました（${_counts(lines, mappings, positions)}）';

  static const exportFailed = '書き出せませんでした';

  /// [message] describes the invalid part of the file (never personal data).
  static String restoreFailed(String message) =>
      '読み込めませんでした。データは変わっていません: $message';
  static const restoreUnexpected = '読み込み中にエラーが発生しました。データは変わっていません';

  static const deleteSection = 'データの削除';
  static const deleteButton = '取り込んだ明細行をすべて削除する';
  static const deleteConfirmMessage = '取り込んだデータをすべて削除します。元に戻せません。';
  static const deleteConfirmCancel = 'キャンセル';
  static const deleteConfirmOk = '削除する';
  static const deleted = '削除しました';
  static const deleteFailed = '削除できませんでした';

  static const deleteAllButton = 'すべてのデータを削除する';
  static const deleteAllConfirmMessage =
      'すべてのデータ（明細行・ICの対応づけ・位置の指定・線の色）を削除します。元に戻せません。';
  static const deletedAll = 'すべてのデータを削除しました';
  static const deleteAllFailed = '削除できませんでした。データは変わっていません';

  static const icMappingSection = 'ICの対応づけ';
  static const icMappingButton = 'ICの対応づけを開く';

  /// The credit the terms of the IC master require (docs/route-map.md).
  static const credit =
      '出典：国土交通省 国土数値情報（高速道路時系列データ）'
      '（https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-N06-2025.html）を加工して作成'
      '\n'
      '一部の料金所・出入口の位置：© OpenStreetMap contributors（ODbL）';
}
