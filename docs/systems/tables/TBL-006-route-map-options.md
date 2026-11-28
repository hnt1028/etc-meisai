# TBL-006 地図の数値の設定（route_map_options）

## 概要

利用者がスライダーなどで決めた、ルートマップの数値（いまは、走行した線の太さ）を、端末内の SQLite に保存するテーブル。1行が、1つの項目。決めていない項目は、行が無く、初期値（[route-map.md](../../route-map.md) の「ルートマップの表示」）を使う。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| テーブル定義 | `lib/infrastructure/repository/database/route_map_options_table.dart` | `RouteMapOptions` |
| データベース | `lib/infrastructure/repository/database/app_database.dart` | `AppDatabase`（`schemaVersion` は 8。7 から 8 へ上げるときに、このテーブルを作る） |
| 生成コード | `lib/infrastructure/repository/database/app_database.g.dart` | （drift が生成する。手で編集しない） |

## 使う箇所

- `lib/infrastructure/repository/route_map_option/route_map_option_repo.dart` の `RouteMapOptionRepo`: 設定の読み書き（[PRC-030](../processes/PRC-030-list-route-map-options.md)、[PRC-031](../processes/PRC-031-save-route-map-option.md)）
- `lib/infrastructure/repository/settings/app_data_repo.dart` の `AppDataRepo`: バックアップの書き出し・読み込み・全削除（[backup-format.md](../../backup-format.md)）

## 項目一覧

物理テーブル名は `route_map_options`。

| 論理カラム名 | 物理カラム名 | データ型 | 桁数 | NotNull |
|---|---|---|---|---|
| 項目 | `option_code` | TEXT | - | ◯ |
| 数値 | `value` | INTEGER | - | ◯ |

- 項目は、`RouteMapOptionValue` の `code`（いまは `lineWidth`: 走行した線の太さ。2〜10、初期値4）
- 範囲の外の値が入っていても、読むときに、範囲に収める（[PRC-030](../processes/PRC-030-list-route-map-options.md)）
- このアプリが知らない項目の行があっても、無視する
- 個人情報ではない（[privacy.md](../../privacy.md)）。端末内にだけ保存する

## キーと制約

- 主キー: `option_code`。同じ項目を選び直すと、置き換わる

## インデックス

主キー以外のインデックスは作らない（行数が少ないため）。

## 関連するテスト

- 単体: `test/infrastructure/repository/route_map_option/route_map_option_repo_test.dart`（保存・置き換え・読み出し・全削除、7から8への更新で作られること）
- 単体: `test/infrastructure/repository/settings/app_data_repo_test.dart`（書き出し・置き換え・全削除に、設定が含まれること）
