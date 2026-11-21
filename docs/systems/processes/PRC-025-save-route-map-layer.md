# PRC-025 地図の表示の保存（SaveRouteMapLayerUC）

## 概要

利用者が選んだ、ルートマップの1つの項目の、表示するか・しないかを保存する。同じ項目の選択は、置き換える。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/route_map/save_route_map_layer_uc.dart` | `SaveRouteMapLayerUC` |
| 使う窓口（選択の保存） | `lib/application/interface/route_map_layer_if.dart` | `RouteMapLayerIF`（`save`） |
| 窓口の実装 | `lib/infrastructure/repository/route_map_layer/route_map_layer_repo.dart` | `RouteMapLayerRepo`（[TBL-005](../tables/TBL-005-route-map-layers.md)） |

## 呼び出し箇所

- [SCR-005](../screens/SCR-005-route-map.md) の OP-10（表示を切り替える）

## 入力

| 名前 | 型 | 意味 |
|---|---|---|
| `layer` | `RouteMapLayerValue` | 項目 |
| `visible` | `bool` | 表示するか |

## 手順

1. `RouteMapLayerIF` の `save` で保存する（同じ項目の選択があれば、置き換わる）

## 出力

- なし（完了したら戻る）

## エラー時の動作

- 保存の失敗は、そのまま呼び出し元に返す。ルートマップは、「設定を保存できませんでした」を表示する

## 関連するテスト

- 単体: `test/application/usecase/route_map/route_map_layer_uc_test.dart`（保存と置き換え、保存の失敗）
