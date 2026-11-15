# TBL-001 利用（trips）

## 概要

取り込んだ利用（1回の入口から出口までの利用）を、端末内の SQLite に保存するテーブル。CSVの1行が1行になる。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| テーブル定義 | `lib/infrastructure/repository/database/trips_table.dart` | `Trips` |
| データベース | `lib/infrastructure/repository/database/app_database.dart` | `AppDatabase` |
| 生成コード | `lib/infrastructure/repository/database/app_database.g.dart` | （drift が生成する。手で編集しない） |

## 使う箇所

- `lib/infrastructure/repository/statements/trip_repo.dart` の `TripRepo` が、読み書きする唯一の箇所

## 項目一覧

物理テーブル名は `trips`。

| 論理カラム名 | 物理カラム名 | データ型 | 桁数 | NotNull |
|---|---|---|---|---|
| ID | `id` | INTEGER | - | はい |
| 重複判定キー | `duplicate_key` | TEXT | - | はい |
| 入口日時 | `entrance_at` | INTEGER（UNIX秒） | - | いいえ |
| 出口日時 | `exit_at` | INTEGER（UNIX秒） | - | はい |
| 入口IC | `entrance_ic` | TEXT | - | いいえ |
| 出口IC | `exit_ic` | TEXT | - | はい |
| 割引前料金 | `gross_fare` | INTEGER | - | いいえ |
| ETC割引額 | `etc_discount` | INTEGER | - | いいえ |
| 通行料金 | `fare` | INTEGER | - | はい |
| 還元額適用料金 | `fare_after_rebate` | INTEGER | - | はい |
| 後納料金 | `postpaid_fare` | INTEGER | - | はい |
| 車種 | `vehicle_type` | TEXT | - | はい |
| 車両番号 | `vehicle_number` | TEXT | - | はい |
| ETCカード番号 | `card_number` | TEXT | - | はい |
| 状態 | `status` | TEXT（`confirmed` / `pending`） | - | はい |
| 割引種別 | `discount_types` | TEXT（`;` 区切り。無いときは空文字） | - | はい |

- 桁数の「-」は、SQLite の型に桁数の指定が無いことを示す
- 金額はすべて円の整数で保存する（小数は使わない）
- 車両番号とETCカード番号は個人情報。端末内にだけ保存する（[privacy.md](../../privacy.md)）

## キーと制約

- 主キー: `id`（自動採番）
- 重複判定のキー: `duplicate_key` に UNIQUE 制約を付ける
  - 値は、入口日時・入口IC・出口IC・ETCカード番号を `|` でつないだ文字列（[csv-format.md](../../csv-format.md) の重複判定）
  - 入口日時と入口ICは空欄になりうる。空欄は NULL 同士が重複と見なされないため、1つの文字列にまとめて UNIQUE にしている

## インデックス

| 名前 | 対象のカラム | ユニーク |
|---|---|---|
| `trips_exit_at` | `exit_at` | いいえ |

- `duplicate_key` の UNIQUE 制約に、SQLite が自動でインデックスを作る
- `trips_exit_at` は、期間での絞り込みと、出口日時順の一覧に使う

## 関連するテスト

- 単体: `test/infrastructure/repository/statements/trip_repo_test.dart`（メモリ上のDBで、保存・上書き・全項目の読み戻し・削除）
