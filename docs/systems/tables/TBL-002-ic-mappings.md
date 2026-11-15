# TBL-002 ICの対応づけ（ic_mappings）

## 概要

利用者が登録した、CSVのIC名とIC地点（[ICマスタ](../../route-map.md)）の対応づけを、端末内の SQLite に保存するテーブル。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| テーブル定義 | `lib/infrastructure/repository/database/ic_mappings_table.dart` | `IcMappings` |
| データベース | `lib/infrastructure/repository/database/app_database.dart` | `AppDatabase`（バージョン2で、このテーブルを作った。1 から上げるときに作る。現在の `schemaVersion` は 3） |
| 生成コード | `lib/infrastructure/repository/database/app_database.g.dart` | （drift が生成する。手で編集しない） |

## 使う箇所

- `lib/infrastructure/repository/ic_mapping/ic_mapping_repo.dart` の `IcMappingRepo` が、読み書きする唯一の箇所

## 項目一覧

物理テーブル名は `ic_mappings`。文字列はUTF-8で保存する（SQLite の初期設定）。

| 論理カラム名 | 物理カラム名 | データ型 | 桁数 | NotNull |
|---|---|---|---|---|
| IC名 | `ic_name` | TEXT | - | ◯ |
| IC地点のID | `point_id` | TEXT | - | ◯ |

- IC名は、CSVの表記のまま（正規化しない）保存する
- IC地点のIDは、ICマスタの `id`（N06の関係ID）。マスタにそのIDが無いとき（マスタを差し替えたとき）は、対応づけが無いものとして扱い、[SCR-004](../screens/SCR-004-ic-mapping.md) に「登録済み（地点が見つからない）」として表示する

## キーと制約

- 主キー: `ic_name`。同じIC名を登録し直すと、IC地点のIDが置き換わる

## インデックス

主キー以外のインデックスは作らない（行数が少ないため）。

## 関連するテスト

- 単体: `test/infrastructure/repository/ic_mapping/ic_repo_test.dart`（保存・読み出し、同じIC名の置き換え、削除、バージョン1のデータベースの更新でテーブルが作られること）
