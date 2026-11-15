# TBL-003 IC位置（ic_positions）

## 概要

利用者が地図をタップして指定した、IC名の位置を、端末内の SQLite に保存するテーブル。ICマスタの位置より優先する（[route-map.md](../../route-map.md) の「位置の優先順」）。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| テーブル定義 | `lib/infrastructure/repository/database/ic_positions_table.dart` | `IcPositions` |
| データベース | `lib/infrastructure/repository/database/app_database.dart` | `AppDatabase`（`schemaVersion` は 3。2 から 3 へ上げるときに、このテーブルを作る） |
| 生成コード | `lib/infrastructure/repository/database/app_database.g.dart` | （drift が生成する。手で編集しない） |

## 使う箇所

- `lib/infrastructure/repository/ic_position/ic_position_repo.dart` の `IcPositionRepo` が、読み書きする唯一の箇所

## 項目一覧

物理テーブル名は `ic_positions`。

| 論理カラム名 | 物理カラム名 | データ型 | 桁数 | NotNull |
|---|---|---|---|---|
| IC名 | `ic_name` | TEXT | - | ◯ |
| 緯度 | `latitude` | REAL（度、-90〜90） | - | ◯ |
| 経度 | `longitude` | REAL（度、-180〜180） | - | ◯ |

- IC名は、CSVの表記のまま（正規化しない）保存する
- 位置は、利用者の走行地点に近い個人情報として扱う。端末内にだけ保存する（[privacy.md](../../privacy.md)）

## キーと制約

- 主キー: `ic_name`。同じIC名を登録し直すと、位置が置き換わる

## インデックス

主キー以外のインデックスは作らない（行数が少ないため）。

## 関連するテスト

- 単体: `test/infrastructure/repository/ic_position/ic_position_repo_test.dart`（保存・読み出し、同じIC名の置き換え、削除、バージョン2のデータベースの更新でテーブルが作られること）
