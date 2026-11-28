# PRC-031 地図の数値の保存（SaveRouteMapOptionUC）

## 概要

利用者が決めた、ルートマップの数値（いまは、走行した線の太さ）を保存する。同じ項目の値は、置き換える。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/route_map/save_route_map_option_uc.dart` | `SaveRouteMapOptionUC` |
| 使う窓口（設定の保存） | `lib/application/interface/route_map_option_if.dart` | `RouteMapOptionIF`（`save`） |
| 窓口の実装 | `lib/infrastructure/repository/route_map_option/route_map_option_repo.dart` | `RouteMapOptionRepo`（[TBL-006](../tables/TBL-006-route-map-options.md)） |

## 呼び出し箇所

- [SCR-005](../screens/SCR-005-route-map.md) の OP-10（「地図の表示」シートのスライダーから指を離したとき）

## 入力

| 名前 | 型 | 意味 |
|---|---|---|
| `option` | `RouteMapOptionValue` | 項目 |
| `value` | `int` | 値 |

## 手順

1. 値を、項目の範囲（最小〜最大）に収める
2. `RouteMapOptionIF` の `save` で保存する（同じ項目の値があれば、置き換わる）

## 出力

- なし（完了したら戻る）

## エラー時の動作

- 保存の失敗は、そのまま呼び出し元に返す。ルートマップは、「設定を保存できませんでした」を表示する

## 関連するテスト

- 単体: `test/application/usecase/route_map/route_map_option_uc_test.dart`（保存と置き換え、範囲に収めること、保存の失敗）
