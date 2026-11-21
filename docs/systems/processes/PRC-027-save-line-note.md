# PRC-027 メモとタグの保存（SaveLineNoteUC）

## 概要

利用者が明細行に書いた、メモと、タグ（「仕事」「私用」などの印。いくつでも）を保存する。その明細行のメモとタグは、置き換わる。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/statements/save_line_note_uc.dart` | `SaveLineNoteUC` |
| 使う窓口（明細行の保存） | `lib/application/interface/statement_line_if.dart` | `StatementLineIF`（`findById`、`updateNote`） |
| 窓口の実装 | `lib/infrastructure/repository/statements/statement_line_repo.dart` | `StatementLineRepo`（[TBL-001](../tables/TBL-001-statement-lines.md)） |

## 呼び出し箇所

- [SCR-003](../screens/SCR-003-statement-detail.md) の OP-6（メモ・タグを編集する）

## 入力

| 名前 | 型 | 意味 |
|---|---|---|
| `id` | `String` | 明細行のID |
| `memo` | `String` | メモ。空でもよい |
| `tags` | `List<String>` | タグ。空でもよい |

## 手順

1. メモと、各タグの前後の空白を取り除く。空のタグと、同じタグの重複は、取り除く
2. 次に当たるときは、`ArgumentError` を投げる（何も保存しない）
   - メモが200文字を超える
   - タグが1つ20文字を超える、または `;`・改行を含む（タグは `;` でつないで保存するため）
   - タグが10個を超える
3. `StatementLineIF` の `findById` で明細行を探す。無ければ `StateError`
4. `updateNote` で、メモとタグを保存する（メモ・タグを空にすると、消える）

## 出力

- なし（完了したら戻る）

## エラー時の動作

- 例外（`ArgumentError`、`StateError`、保存の失敗）を、そのまま呼び出し元に返す。詳細画面は、「保存できませんでした」を表示する

## 補足

- メモとタグは、CSVの取り込みで変わらない。同じ明細行をもう一度取り込んで上書きしても、残る（取り込みは、メモとタグの列に触れない）
- 利用者の個人的な書き込みなので、書き出し・読み込みのバックアップに含める（[backup-format.md](../../backup-format.md)）

## 関連するテスト

- 単体: `test/application/usecase/statements/line_note_uc_test.dart`（保存、前後の空白・空・重複の除去、空にして消すこと、上限、上限を超える値と不正な文字、見つからない明細行、保存の失敗）
- 単体: `test/infrastructure/repository/statements/statement_line_repo_test.dart`（保存と読み出し、取り込み直しで残ること、6から7への更新）
