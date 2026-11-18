# PRC-022 事業者の線の色の保存（SaveOperatorColorUC）

## 概要

利用者が選んだ、道路の事業者の、地図の線の色を保存する。同じ事業者の色は、置き換える。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/route_map/save_operator_color_uc.dart` | `SaveOperatorColorUC` |
| 事業者の一覧 | `lib/application/usecase/aggregation/route_operators.dart` | `knownOperators` |
| 使う窓口（色の保存） | `lib/application/interface/operator_color_if.dart` | `OperatorColorIF`（`save`） |
| 窓口の実装 | `lib/infrastructure/repository/operator_color/operator_color_repo.dart` | `OperatorColorRepo`（[TBL-004](../tables/TBL-004-operator-colors.md)） |

## 呼び出し箇所

- [SCR-001](../screens/SCR-001-settings.md) の OP-7（事業者の線の色を選ぶ）

## 入力

| 名前 | 型 | 意味 |
|---|---|---|
| `operatorName` | `String` | 事業者名 |
| `color` | `int` | 色（ARGB。透明度は無視する） |

## 手順

1. `operatorName` が、事業者の表（`knownOperators`）に無ければ、`ArgumentError` を投げる
2. 色の透明度を、不透明にそろえる（`0xFF000000 | (color & 0xFFFFFF)`）
3. `OperatorColorIF` の `save` で保存する（同じ事業者の色があれば、置き換わる）

## 出力

- なし（完了したら戻る）

## エラー時の動作

- 例外（`ArgumentError`、保存の失敗）を、そのまま呼び出し元に返す。設定画面は、「保存できませんでした」を表示する

## 関連するテスト

- 単体: `test/application/usecase/route_map/operator_color_uc_test.dart`（保存と置き換え、不透明にすること、表に無い事業者、保存の失敗）
