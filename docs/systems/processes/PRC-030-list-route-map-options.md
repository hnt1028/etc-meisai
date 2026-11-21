# PRC-030 地図の数値の取得（ListRouteMapOptionsUC）

## 概要

ルートマップの数値（いまは、走行した線の太さ）を返す。利用者が決めていれば、その値。なければ、初期値。ルートマップの描き方と、「地図の表示」シートのスライダーが使う。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/route_map/list_route_map_options_uc.dart` | `ListRouteMapOptionsUC` |
| 結果の受け渡し | `lib/application/dto/route_map_option_dto.dart` | `RouteMapOptionDTO` |
| 項目、初期値、範囲 | `lib/domain/value/route_map_option_value.dart` | `RouteMapOptionValue`（`defaultValue`、`minimum`、`maximum`） |
| 使う窓口（設定の保存） | `lib/application/interface/route_map_option_if.dart` | `RouteMapOptionIF`（`findAll`） |
| 窓口の実装 | `lib/infrastructure/repository/route_map_option/route_map_option_repo.dart` | `RouteMapOptionRepo`（[TBL-006](../tables/TBL-006-route-map-options.md)） |

## 呼び出し箇所

- [SCR-005](../screens/SCR-005-route-map.md) の、地図の描き方と、OP-10（表示を切り替える）のシートのスライダー。`routeMapOptionsProvider` を通して、1つの結果を共有する

## 入力

なし。

## 手順

1. `RouteMapOptionIF` の `findAll` で、利用者が決めた値を取得する
2. `RouteMapOptionValue` の順に、`RouteMapOptionDTO` を作る。決めた値があればその値、なければ初期値。値は、範囲（最小〜最大）に収める
3. このアプリが知らない項目は、結果に入れない

## 出力

`List<RouteMapOptionDTO>`（項目 `option`、値 `value`）

## エラー時の動作

- 読み取りの失敗は、そのまま呼び出し元に返す。ルートマップは、初期値で描く（メッセージは出さない）

## 関連するテスト

- 単体: `test/application/usecase/route_map/route_map_option_uc_test.dart`（初期値、決めた値、範囲外の値、知らない項目、読み取りの失敗）
