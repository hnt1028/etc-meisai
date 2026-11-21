# PRC-024 地図の表示の取得（ListRouteMapLayersUC）

## 概要

ルートマップの、各項目を、表示するか・しないかを返す。利用者が選んでいれば、その選択。なければ、初期値。ルートマップの描き方と、「地図の表示」シートが使う。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/route_map/list_route_map_layers_uc.dart` | `ListRouteMapLayersUC` |
| 結果の受け渡し | `lib/application/dto/route_map_layer_dto.dart` | `RouteMapLayerDTO` |
| 項目と初期値 | `lib/domain/value/route_map_layer_value.dart` | `RouteMapLayerValue`（`defaultVisible`） |
| 使う窓口（選択の保存） | `lib/application/interface/route_map_layer_if.dart` | `RouteMapLayerIF`（`findAll`） |
| 窓口の実装 | `lib/infrastructure/repository/route_map_layer/route_map_layer_repo.dart` | `RouteMapLayerRepo`（[TBL-005](../tables/TBL-005-route-map-layers.md)） |

## 呼び出し箇所

- [SCR-005](../screens/SCR-005-route-map.md) の、地図の描き方と、OP-10（表示を切り替える）のシート
- どちらも、`routeMapLayersProvider` を通して、1つの結果を共有する。データの置き換え・削除（読み込み、全削除）と、選択の保存のあとに、読み直す

## 入力

なし。

## 手順

1. `RouteMapLayerIF` の `findAll` で、利用者が選んだ項目を取得する
2. `RouteMapLayerValue` の順に、項目ごとの `RouteMapLayerDTO` を作る
   - 利用者が選んでいれば、その選択
   - なければ、初期値（`defaultVisible`）
3. このアプリが知らない項目が保存されていても、無視する（結果に入れない）

## 出力

`List<RouteMapLayerDTO>`（`RouteMapLayerValue` の順）

| フィールド | 型 | 意味 |
|---|---|---|
| `layer` | `RouteMapLayerValue` | 項目 |
| `visible` | `bool` | 表示するか |

## エラー時の動作

- 読み取りの失敗は、そのまま呼び出し元に返す。ルートマップは、初期値の表示で描く（メッセージは出さない）

## 関連するテスト

- 単体: `test/application/usecase/route_map/route_map_layer_uc_test.dart`（初期値、選択と初期値の混在、知らない項目、読み取りの失敗）
