# TBL-001 明細行（statement_lines）

## 概要

取り込んだ利用明細の1明細（入口から出口までの1回の利用）を、端末内の SQLite に保存するテーブル。CSVの1行が1行になる。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| テーブル定義 | `lib/infrastructure/repository/database/statement_lines_table.dart` | `StatementLines` |
| 車種の変換 | `lib/infrastructure/repository/database/vehicle_type_converter.dart` | `VehicleTypeConverter` |
| データベース | `lib/infrastructure/repository/database/app_database.dart` | `AppDatabase` |
| 生成コード | `lib/infrastructure/repository/database/app_database.g.dart` | （drift が生成する。手で編集しない） |

## 使う箇所

- `lib/infrastructure/repository/statements/statement_line_repo.dart` の `StatementLineRepo` が、読み書きする唯一の箇所

## 項目一覧

物理テーブル名は `statement_lines`。文字列はUTF-8で保存する（SQLite の初期設定）。

| 論理カラム名 | 物理カラム名 | データ型 | 桁数 | NotNull |
|---|---|---|---|---|
| ID | `id` | TEXT（UUIDv7） | 36 | ◯ |
| 重複判定キー | `duplicate_key` | TEXT | - | ◯ |
| 入口日時 | `entrance_at` | INTEGER（UNIX秒） | - | |
| 出口日時 | `exit_at` | INTEGER（UNIX秒） | - | ◯ |
| 入口IC | `entrance_ic` | TEXT | - | |
| 出口IC | `exit_ic` | TEXT | - | ◯ |
| 割引前料金 | `gross_fare` | INTEGER | - | |
| ETC割引額 | `etc_discount` | INTEGER | - | |
| 通行料金 | `fare` | INTEGER | - | ◯ |
| 還元額適用料金 | `fare_after_rebate` | INTEGER | - | ◯ |
| 後納料金 | `postpaid_fare` | INTEGER | - | ◯ |
| 車種 | `vehicle_type` | INTEGER（1〜5。下の「車種の値」） | - | ◯ |
| 車両番号 | `vehicle_number` | INTEGER | - | |
| ETCカード番号 | `card_number` | TEXT | - | ◯ |
| 状態 | `status` | INTEGER（0: 確定、1: 確認中） | - | ◯ |
| 割引種別 | `discount_types` | TEXT（`;` 区切り。無いときは空文字） | - | ◯ |

- NotNull の列は「◯」、NULL を許す列は空欄で表す
- 桁数の「-」は、SQLite の型に桁数の指定が無いことを示す
- IDは、保存するときにアプリが UUIDv7 を作って入れる。同じ重複判定キーの行を上書きしても、IDは変わらない
- 金額はすべて円の整数で保存する（小数は使わない）
- 状態は `ConfirmationStatusValue` の並び順の番号で保存する。並び順を変えない
- 車両番号は、CSVで空欄のとき NULL（スキーマ版4から、NULL を許す。版3までは NotNull だった）。利用者が入力すると、数字が入る（[PRC-014](../processes/PRC-014-save-vehicle-number.md)）。NULL の行だけ、更新できる
- 車両番号とETCカード番号は個人情報。端末内にだけ保存する（[privacy.md](../../privacy.md)）

### 車種の値

CSVの「車種」の番号をそのまま保存する。名前への変換は、コードの `VehicleTypeValue`（`lib/domain/value/vehicle_type_value.dart`）が行う。

| 値 | 名前 |
|---|---|
| 1 | 普通車 |
| 2 | 大型車 |
| 3 | 特大車 |
| 4 | 中型車 |
| 5 | 軽自動車等 |

- 出典は [ETC利用照会サービスの表示内容の説明](https://www.etc-meisai.jp/soukou_meisai_exp.html) の、東日本・中日本・西日本高速道路の車種区分１
- 道路事業者によって、同じ番号に別の名前が付く（例: 青森県道路公社の4は「普通車」）。CSVには道路事業者が出ないため、区分１の名前だけを使う

## キーと制約

- 主キー: `id`
- 重複判定のキー: `duplicate_key` に UNIQUE 制約を付ける
  - 値は、入口日時・入口IC・出口IC・ETCカード番号を `|` でつないだ文字列（[csv-format.md](../../csv-format.md) の重複判定）
  - 入口日時と入口ICは空欄になりうる。空欄は NULL 同士が重複と見なされないため、1つの文字列にまとめて UNIQUE にしている

## インデックス

| 名前 | 対象のカラム | ユニーク |
|---|---|---|
| `statement_lines_exit_at` | `exit_at` | いいえ |

- `duplicate_key` の UNIQUE 制約に、SQLite が自動でインデックスを作る
- `statement_lines_exit_at` は、期間での絞り込みと、出口日時順の一覧に使う

## 関連するテスト

- 単体: `test/infrastructure/repository/statements/statement_line_repo_test.dart`（メモリ上のDBで、保存・上書き・全項目の読み戻し・ID・車種と状態の数値・削除）
