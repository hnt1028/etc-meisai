# PRC-026 路線図の作成（ListRouteNetworkUC）

## 概要

ICマスタの、すべての道路を、地図に描く線にする。「路線図（すべての路線）」と「路線図の路線名」に使う。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/route_map/list_route_network_uc.dart` | `ListRouteNetworkUC` |
| 結果の受け渡し | `lib/application/dto/route_network_dto.dart` | `RouteNetworkDTO`、`RouteNetworkLineDTO`、`RouteNetworkLabelDTO` |
| 使う窓口（ICマスタ） | `lib/application/interface/ic_master_if.dart` | `IcMasterIF`（`findAll`、`findLinks`） |

## 呼び出し箇所

- [SCR-005](../screens/SCR-005-route-map.md) の、地図の描き方。`routeNetworkProvider` を通して、1度だけ作る（ICマスタは、アプリの実行中に変わらない）

## 入力

なし。

## 手順

1. `IcMasterIF` の `findAll` で地点を、`findLinks` でリンク（隣り合う地点の組と、間の道路の形）を取得する
2. リンクごとに、線を作る。前の地点、間の道路の形の点、後の地点の順。どちらかの地点がICマスタに無いリンクは、飛ばす
3. 線の路線名は、2つの地点が共通に持つ路線名の、先頭。共通が無ければ、`null`
4. 路線名ごとに、道のりが最も長いリンクを選び、その線の真ん中の点を、路線名を書く位置にする

## 出力

`RouteNetworkDTO`

| フィールド | 型 | 意味 |
|---|---|---|
| `lines` | `List<RouteNetworkLineDTO>` | リンクごとの線（路線名、点の並び） |
| `labels` | `List<RouteNetworkLabelDTO>` | 路線名と、書く位置（路線ごとに1つ） |

## エラー時の動作

- 失敗は、そのまま呼び出し元に返す。ルートマップは、路線図を描かない（走行した路線図などは、そのまま描く）

## 関連するテスト

- 単体: `test/application/usecase/route_map/list_route_network_uc_test.dart`（道路の形に沿った線、共通の路線が無いリンク、路線名の位置、地点が無いリンク）
