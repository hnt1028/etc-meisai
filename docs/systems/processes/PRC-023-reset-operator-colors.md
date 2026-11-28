# PRC-023 事業者の線の色の初期値への復帰（ResetOperatorColorsUC）

## 概要

利用者が選んだ色を取り消して、初期値に戻す。事業者を指定したときは、その事業者だけ。指定しないときは、すべて。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/route_map/reset_operator_colors_uc.dart` | `ResetOperatorColorsUC` |
| 使う窓口（色の保存） | `lib/application/interface/operator_color_if.dart` | `OperatorColorIF`（`delete`、`deleteAll`） |
| 窓口の実装 | `lib/infrastructure/repository/operator_color/operator_color_repo.dart` | `OperatorColorRepo`（[TBL-004](../tables/TBL-004-operator-colors.md)） |

## 呼び出し箇所

- [SCR-001](../screens/SCR-001-settings.md) の OP-8（事業者の線の色を初期値に戻す）、OP-9（すべての線の色を初期値に戻す）

## 入力

| 名前 | 型 | 意味 |
|---|---|---|
| `operatorName` | `String?` | 初期値に戻す事業者。`null` は、すべて |

## 手順

1. `operatorName` があれば、`OperatorColorIF` の `delete` で、その事業者の色を削除する。色が無い事業者でも、エラーにしない
2. `operatorName` が `null` なら、`deleteAll` で、すべての色を削除する

## 出力

- なし（完了したら戻る）

## エラー時の動作

- 削除の失敗は、そのまま呼び出し元に返す。設定画面は、「保存できませんでした」を表示する

## 関連するテスト

- 単体: `test/application/usecase/route_map/operator_color_uc_test.dart`（1事業者、すべて、色が無い事業者）
