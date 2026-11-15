# PRC-004 明細行の一覧の取得（ListStatementLinesUC）

## 概要

保存済みの明細行を、絞り込み条件で絞り、出口日時の新しい順に並べて、合計金額とともに返す。仕様は [specification.md](../../specification.md) の 3.1 に従う。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/statements/list_statement_lines_uc.dart` | `ListStatementLinesUC` |
| 結果の受け渡し | `lib/application/dto/statement_list_dto.dart` | `StatementListDTO` |
| 結果の明細行 | `lib/application/dto/statement_line_dto.dart` | `StatementLineDTO` |
| 使う窓口（明細行の保存・取得） | `lib/application/interface/statement_line_if.dart` | `StatementLineIF`（`findAll`） |

## 呼び出し箇所

- [SCR-002](../screens/SCR-002-statement-list.md) の OP-1（一覧を表示する）と OP-2（絞り込む）が呼び出す

## 入力

| 名前 | 型 | 意味 |
|---|---|---|
| `from` | `DateTime?` | 期間の開始日。`null` なら下限なし |
| `to` | `DateTime?` | 期間の終了日。`null` なら上限なし |
| `vehicleNumber` | `int?` | 車両番号。`null` なら絞らない |
| `cardNumberSuffix` | `String?` | ETCカード番号の下4桁。`null` なら絞らない |

- `from`、`to` は日付だけを使う（時刻は無視する）

## 手順

1. `StatementLineIF` の `findAll` で、保存済みの明細行をすべて取得する
2. 絞り込み用の選択肢を作る。絞り込む前の全明細行から、車両番号（数の小さい順）とETCカード番号の下4桁（文字の順）を、重複なく集める
3. 次の条件をすべて満たす明細行に絞る（`null` の条件は使わない）
   - 出口日時の日付が、`from` 以後（`from` を含む）
   - 出口日時の日付が、`to` 以前（`to` を含む）
   - 車両番号が `vehicleNumber` と等しい
   - ETCカード番号の下4桁が `cardNumberSuffix` と等しい
4. 出口日時の新しい順に並べる（同じ日時は、保存済みの順のまま）
5. 絞った明細行の、通行料金・還元額適用料金・後納料金を、それぞれ合計する（確認中の明細行も含める）
6. `Entity` を `StatementLineDTO` に詰め替える。ETCカード番号と車両番号は、DTO の明細行には入れない

## シーケンス図

```mermaid
sequenceDiagram
    participant UI as 利用明細一覧の画面
    participant UC as 一覧取得の処理<br/>(ListStatementLinesUC)
    participant SL as 明細行の保存窓口<br/>(StatementLineIF)

    UI-)UC: execute(from, to, vehicleNumber, cardNumberSuffix)
    activate UC
    UC-)SL: findAll()
    activate SL
    SL--)UC: 明細行のリスト
    deactivate SL
    Note over UC: 絞り込み用の選択肢（車両番号、カード番号の下4桁）を集める
    Note over UC: 期間・車両番号・カード番号で明細行を絞る
    Note over UC: 出口日時の新しい順に並べる
    Note over UC: 通行料金・還元額適用料金・後納料金を合計する
    UC--)UI: StatementListDTO
    deactivate UC
```

## 出力

`StatementListDTO`

| 項目 | 型 | 内容 |
|---|---|---|
| `lines` | `List<StatementLineDTO>` | 絞った明細行（出口日時の新しい順） |
| `totalFare` | `int` | 通行料金の合計（円） |
| `totalFareAfterRebate` | `int` | 還元額適用料金の合計（円） |
| `totalPostpaidFare` | `int` | 後納料金の合計（円） |
| `vehicleNumberChoices` | `List<int>` | 絞り込みで選べる車両番号 |
| `cardNumberChoices` | `List<String>` | 絞り込みで選べるETCカード番号（下4桁） |

`StatementLineDTO`: `entranceAt`（`DateTime?`）、`exitAt`、`entranceIc`（`String?`）、`exitIc`、`fare`（`int`）、`status`（`ConfirmationStatusValue`）

## エラー時の動作

- 保存済みの明細行の取得に失敗したときは、例外をそのまま呼び出し元に返す。呼び出し元（画面）が ER-1 を表示する

## 関連するテスト

- 単体: `test/application/usecase/statements/list_statement_lines_uc_test.dart`（0件、並び順、期間の境界日を含むこと、車両番号・カード番号の絞り込み、合計と内訳、入口が空欄の行、選択肢が絞り込み前の全体から作られること、カード番号が下4桁になること）
