# PRC-021 事業者の線の色の取得（ListOperatorColorsUC）

## 概要

道路の事業者ごとの、地図の線の色を返す。利用者が選んだ色があれば、その色。なければ、初期値。設定画面の「地図の線の色」と、地図（ルートマップ、明細詳細）が使う。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/route_map/list_operator_colors_uc.dart` | `ListOperatorColorsUC` |
| 結果の受け渡し | `lib/application/dto/operator_color_dto.dart` | `OperatorColorDTO` |
| 初期値 | `lib/application/usecase/route_map/operator_default_colors.dart` | `defaultOperatorColors` |
| 事業者の一覧 | `lib/application/usecase/aggregation/route_operators.dart` | `knownOperators` |
| 使う窓口（色の保存） | `lib/application/interface/operator_color_if.dart` | `OperatorColorIF`（`findAll`） |
| 窓口の実装 | `lib/infrastructure/repository/operator_color/operator_color_repo.dart` | `OperatorColorRepo`（[TBL-004](../tables/TBL-004-operator-colors.md)） |

## 呼び出し箇所

- [SCR-001](../screens/SCR-001-settings.md) の「地図の線の色」の表示
- [SCR-005](../screens/SCR-005-route-map.md)（ルートマップ）、[SCR-003](../screens/SCR-003-statement-detail.md)（明細詳細の地図）の、線の色
- いずれも、`operatorColorsProvider` を通して、1つの結果を共有する。データの置き換え・削除（読み込み、全削除）と、設定画面での変更のあとに、読み直す

## 入力

なし。

## 手順

1. `OperatorColorIF` の `findAll` で、利用者が選んだ色を取得する
2. 事業者の表（`knownOperators`）の順に、事業者ごとの `OperatorColorDTO` を作る
   - 利用者が選んだ色があれば、その色、`isDefault` は `false`
   - なければ、初期値（`defaultOperatorColors`）、`isDefault` は `true`
3. 事業者の表に無い事業者の色が保存されていても、無視する（結果に入れない）

## 出力

`List<OperatorColorDTO>`（事業者の表の順）

| フィールド | 型 | 意味 |
|---|---|---|
| `operatorName` | `String` | 事業者名 |
| `color` | `int` | 使う色（不透明のARGB） |
| `isDefault` | `bool` | 利用者が選んでいない（初期値である） |

## エラー時の動作

- 読み取りの失敗は、そのまま呼び出し元に返す。設定画面は、「線の色を読み込めませんでした」を表示する。地図は、初期値の色で線を描く

## 関連するテスト

- 単体: `test/application/usecase/route_map/operator_color_uc_test.dart`（初期値、選んだ色と初期値の混在、表に無い事業者、読み取りの失敗）
