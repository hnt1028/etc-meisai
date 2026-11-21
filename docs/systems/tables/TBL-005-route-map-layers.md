# TBL-005 地図の表示の選択（route_map_layers）

## 概要

利用者が選んだ、ルートマップに何を表示するかを、端末内の SQLite に保存するテーブル。1行が、1つの項目（路線図、走行した路線図など）の、表示するか・しないか。選んでいない項目は、行が無く、初期値（[route-map.md](../../route-map.md) の「ルートマップの表示」）を使う。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| テーブル定義 | `lib/infrastructure/repository/database/route_map_layers_table.dart` | `RouteMapLayers` |
| データベース | `lib/infrastructure/repository/database/app_database.dart` | `AppDatabase`（`schemaVersion` は 6。5 から 6 へ上げるときに、このテーブルを作る） |
| 生成コード | `lib/infrastructure/repository/database/app_database.g.dart` | （drift が生成する。手で編集しない） |

## 使う箇所

- `lib/infrastructure/repository/route_map_layer/route_map_layer_repo.dart` の `RouteMapLayerRepo`: 選択の読み書き（[PRC-024](../processes/PRC-024-list-route-map-layers.md)、[PRC-025](../processes/PRC-025-save-route-map-layer.md)）
- `lib/infrastructure/repository/settings/app_data_repo.dart` の `AppDataRepo`: バックアップの書き出し・読み込み・全削除（[backup-format.md](../../backup-format.md)）

## 項目一覧

物理テーブル名は `route_map_layers`。

| 論理カラム名 | 物理カラム名 | データ型 | 桁数 | NotNull |
|---|---|---|---|---|
| 項目 | `layer_code` | TEXT | - | ◯ |
| 表示する | `visible` | BOOLEAN | - | ◯ |

- 項目は、`RouteMapLayerValue` の `code`（`network`、`networkNames`、`traveled`、`markers`、`pending`、`scaleByCount`）
- このアプリが知らない項目の行があっても、無視する（[PRC-024](../processes/PRC-024-list-route-map-layers.md)）
- 個人情報ではない（[privacy.md](../../privacy.md)）。端末内にだけ保存する

## キーと制約

- 主キー: `layer_code`。同じ項目を選び直すと、置き換わる

## インデックス

主キー以外のインデックスは作らない（行数が最大6のため）。

## 関連するテスト

- 単体: `test/infrastructure/repository/route_map_layer/route_map_layer_repo_test.dart`（保存・置き換え・読み出し・全削除、5から6への更新で作られること）
- 単体: `test/infrastructure/repository/settings/app_data_repo_test.dart`（書き出し・置き換え・全削除に、選択が含まれること）
