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

  static const deleteSection = '取り込んだデータの削除';
  static const deleteButton = 'すべて削除する';
  static const deleteConfirmMessage = '取り込んだデータをすべて削除します。元に戻せません。';
  static const deleteConfirmCancel = 'キャンセル';
  static const deleteConfirmOk = '削除する';
  static const deleted = '削除しました';
  static const deleteFailed = '削除できませんでした';
}
