# SCR-001 設定

## 概要

利用明細CSVの取り込みと、取り込んだデータの削除を行う画面（[specification.md](../../specification.md) の 3.3）。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 画面 | `lib/userinterface/settings/settings_screen.dart` | `SettingsScreen` |
| 画面の状態と操作 | `lib/userinterface/settings/settings_controller.dart` | `SettingsController`、`SettingsState` |
| 画面の文言 | `lib/userinterface/settings/settings_strings.dart` | `SettingsStrings` |
| ファイル選択 | `lib/userinterface/settings/csv_picker.dart` | `CsvPicker`（関数の型）、`pickCsv` |
| 依存の受け口 | `lib/userinterface/settings/settings_providers.dart` | 各 `Provider`（実体は `lib/main.dart` で渡す） |

## 呼び出し箇所

- ルート `/settings`（`lib/userinterface/app.dart` の `GoRouter`）。現時点では、この画面だけが存在し、起動時に表示する

## 基本設計

### 画面イメージ

```
┌─────────────────────────────┐
│ 設定                        │
├─────────────────────────────┤
│ 利用明細CSVの取り込み       │
│ [ CSVを選んで取り込む ]     │
│                             │
│ 追加 12 件 / 上書き 3 件 /  │  ← 取り込み後に表示
│ 無視 100 件                 │
│ 取り込めませんでした: …     │  ← 失敗したときに表示
├─────────────────────────────┤
│ 取り込んだデータの削除      │
│ [ すべて削除する ]          │
└─────────────────────────────┘
```

### 入出力項目一覧

| 項目 | 入力/出力 | 型 | 表示形式 |
|---|---|---|---|
| 取り込みボタン | 入力 | ボタン | 「CSVを選んで取り込む」。処理中は押せない |
| 取り込み結果 | 出力 | `ImportResultDTO` | 「追加 N 件 / 上書き N 件 / 無視 N 件」。まだ取り込んでいないときは表示しない |
| 取り込みエラー | 出力 | 文字列 | 「取り込めませんでした: 」に、不正な箇所の説明を続ける（[PRC-002](../processes/PRC-002-parse-statement.md) のエラー）。無いときは表示しない |
| 削除ボタン | 入力 | ボタン | 「すべて削除する」。処理中は押せない |
| 削除の確認 | 入力 | ダイアログ | 「取り込んだデータをすべて削除します。元に戻せません。」と、「キャンセル」「削除する」 |
| 処理中の表示 | 出力 | 進捗の表示 | 取り込み・削除の間、表示する |

### 操作一覧

| 操作ID | 操作 | きっかけ | 動作 | 遷移先 |
|---|---|---|---|---|
| OP-1 | CSVを取り込む | 取り込みボタンのタップ | ファイル選択（端末の標準画面）を開き、選んだCSVを取り込む。選ばなかったときは何もしない。完了したら、取り込み結果を表示する | なし |
| OP-2 | データを削除する | 削除ボタンのタップ | 確認ダイアログを出す。「削除する」を選んだら、すべて削除し、「削除しました」を表示する。「キャンセル」なら何もしない | なし |

### エラー一覧

| ID | 発生する場面 | 表示する文言（文字列定数） | 操作の続け方 |
|---|---|---|---|
| ER-1 | OP-1 で、CSVの形式が不正（[PRC-002](../processes/PRC-002-parse-statement.md) の `FormatException`） | `SettingsStrings.importFailed(message)` | 既存のデータは変わらない。CSVを直して、もう一度取り込む |
| ER-2 | OP-1 で、形式以外の失敗（保存の失敗など） | `SettingsStrings.importUnexpected` | 保存の途中で失敗すると、一部だけ取り込まれていることがある。もう一度取り込めば、同じ明細行は重複しない。直らないときは、データを削除して取り込み直す |
| ER-3 | OP-2 で、削除に失敗 | `SettingsStrings.deleteFailed` | もう一度削除する |

- ER-2、ER-3 には、失敗の詳細（例外の内容）を出さない。個人情報が含まれることがあるため（[privacy.md](../../privacy.md)）

## 詳細設計

### 画面から呼ばれる処理

シーケンス図は、各処理の設計書に書く。

| 操作ID | 呼ぶ処理 | 設計書 |
|---|---|---|
| OP-1 | 利用明細CSVの取込（`ImportStatementUC`） | [PRC-001](../processes/PRC-001-import-statement.md) |
| OP-2 | 取り込んだ明細行の全削除（`DeleteAllStatementLinesUC`） | [PRC-003](../processes/PRC-003-delete-all-statement-lines.md) |

- ファイル選択は画面側の処理（Userinterface）で、業務の処理ではない。選んだCSVのバイト列だけを、処理に渡す
- 画面は `StatementLineEntity` を扱わない。結果は `ImportResultDTO` で受け取る

## 関連するテスト

- ウィジェット: `test/userinterface/settings/settings_screen_test.dart`（初期表示、取り込み結果、取り込みエラー、キャンセル、削除の確認、処理中）
- 結合: `integration_test/settings_import_test.dart`（画面からDBまで、`lib/main.dart` と同じ組み立てで実行する。ファイル選択だけを差し替える。架空のCSV（`test/fixtures/statement_fixture.dart`）を取り込むと「追加 3 件」、もう一度取り込むと「上書き 1 件・無視 2 件」、削除するともう一度「追加 3 件」になること。形式が不正なCSVは、エラーを表示して、何も保存しないこと）
- 単体: `test/application/usecase/settings/delete_all_statement_lines_uc_test.dart`（PRC-003）、`test/userinterface/settings/settings_controller_test.dart`（画面の状態と操作）
