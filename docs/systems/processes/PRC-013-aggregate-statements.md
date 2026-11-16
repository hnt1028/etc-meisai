# PRC-013 明細行の集計（AggregateStatementsUC）

## 概要

保存済みの明細行を絞り込み条件で絞り、期間別・事業者別・路線別・IC別・時間帯別・割引種別別の集計と、合計を返す。絞り込みの規則は [PRC-004](PRC-004-list-statement-lines.md) と同じ。集計の定義は [aggregation.md](../../aggregation.md) に従う。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/aggregation/aggregate_statements_uc.dart` | `AggregateStatementsUC` |
| 結果の受け渡し | `lib/application/dto/aggregation_dto.dart` | `AggregationDTO` |
| 結果の合計 | `lib/application/dto/aggregation_summary_dto.dart` | `AggregationSummaryDTO` |
| 結果の行 | `lib/application/dto/aggregation_row_dto.dart` | `AggregationRowDTO` |
| 使う部品（事業者の推定） | `lib/application/usecase/aggregation/route_operators.dart` | `routeOperatorOf`、`operatorOfRoutes` |
| 使う部品（絞り込み） | `lib/application/usecase/statements/statement_filter.dart` | `filterStatementLines` ほか。PRC-004 と共通 |
| 使う部品（IC名の照合、路線名の決定） | `lib/application/usecase/ic_mapping/ic_lookup.dart` | `IcLookup`（`routeNamesOf`） |
| 使う窓口 | `StatementLineIF`、`IcMasterIF`、`IcMappingIF`、`IcPositionIF` | 各 `findAll`。PRC-009 と同じ |

## 呼び出し箇所

- [SCR-006](../screens/SCR-006-aggregation.md) の OP-1（集計を表示する）、OP-2（絞り込む）、OP-7（再読み込みする）が呼び出す

## 入力

[PRC-004](PRC-004-list-statement-lines.md) と同じ（`from`、`to`、`vehicleNumber`、`cardNumberSuffix`）。

## 手順

1. `StatementLineIF`、`IcMasterIF`、`IcMappingIF`、`IcPositionIF` の `findAll` で、明細行、ICマスタ、対応づけ、位置の指定を取得し、`IcLookup` を作る
2. 絞り込み用の選択肢を、絞り込む前の全明細行から集める（PRC-004 と同じ）
3. 明細行を絞る（PRC-004 と同じ）
4. 合計（回数、利用額、割引額）を求める
5. 期間別を求める。出口日時の日付から、週（月曜日の日付）・月・年の3通りの行を作る。新しい期間が先
6. 明細行ごとに路線名を `IcLookup` で決め、事業者を `operatorOfRoutes` で決めて、事業者別を求める。利用額の多い順（同額は名前順）
7. 路線別、IC別を求める。回数の多い順（同数は名前順）で、上位10件
8. 時間帯別（出口の時刻の「時」。0〜23のすべて）、割引種別別（回数の多い順、同数は名前順）を求める

## シーケンス図

```mermaid
sequenceDiagram
    participant UI as 集計の画面
    participant UC as 集計の処理<br/>(AggregateStatementsUC)
    participant SL as 明細行の保存窓口<br/>(StatementLineIF)
    participant IM as ICマスタ・対応づけ・位置の窓口<br/>(IcMasterIF, IcMappingIF, IcPositionIF)

    UI-)UC: execute(from, to, vehicleNumber, cardNumberSuffix)
    activate UC
    UC-)SL: findAll()
    activate SL
    SL--)UC: 明細行のリスト
    deactivate SL
    UC-)IM: findAll()
    activate IM
    IM--)UC: ICマスタ・対応づけ・位置の指定
    deactivate IM
    Note over UC: 期間・車両番号・カード番号で明細行を絞る
    Note over UC: 合計、期間別、事業者別、路線別、IC別、時間帯別、割引種別別を数える
    UC--)UI: AggregationDTO
    deactivate UC
```

## 出力

`AggregationDTO`

| 項目 | 型 | 内容 |
|---|---|---|
| `summary` | `AggregationSummaryDTO` | `lineCount`、`fareTotal`、`discountTotal` |
| `weeks`、`months`、`years` | `List<AggregationRowDTO>` | 期間別。`label` は「2026/01/05」（週の月曜日）、「2026/01」、「2026」 |
| `operators` | `List<AggregationRowDTO>` | 事業者別。`label` は事業者名、「複数の事業者」「不明」 |
| `routes` | `List<AggregationRowDTO>` | 路線別（上位10件）。`fare`、`discount` は `null` |
| `ics` | `List<AggregationRowDTO>` | IC別（上位10件）。`fare`、`discount` は `null` |
| `hours` | `List<AggregationRowDTO>` | 時間帯別。`label` は「0」〜「23」 |
| `discountTypes` | `List<AggregationRowDTO>` | 割引種別別。`fare` は `null` |
| `vehicleNumberChoices`、`cardNumberChoices` | `List<int>`、`List<String>` | 絞り込みで選べる値 |

`AggregationRowDTO`: `label`（`String`）、`count`（`int`）、`fare`（`int?`）、`discount`（`int?`）。`null` は、その集計では出さない値

## エラー時の動作

- 取得に失敗したときは、例外をそのまま呼び出し元に返す。呼び出し元（画面）が [SCR-006](../screens/SCR-006-aggregation.md) の ER-1 を表示する

## 関連するテスト

- 単体: `test/application/usecase/aggregation/aggregate_statements_uc_test.dart`（0件、合計、週・月・年の境界、割引なしの割引額、事業者別（1つ・複数・不明）、路線別・IC別の上位10件と同数の並び、入口が空欄の行、時間帯別が24行そろうこと、割引種別別、絞り込みと選択肢、取得の失敗）
- 単体: `test/application/usecase/aggregation/route_operators_test.dart`（推定の表、複数の事業者、不明）
