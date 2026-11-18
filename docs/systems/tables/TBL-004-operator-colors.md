# TBL-004 事業者の線の色（operator_colors）

## 概要

利用者が選んだ、道路の事業者ごとの、地図の線の色を、端末内の SQLite に保存するテーブル。選んでいない事業者は、行が無く、初期値（[route-map.md](../../route-map.md) の「線の色」）を使う。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| テーブル定義 | `lib/infrastructure/repository/database/operator_colors_table.dart` | `OperatorColors` |
| データベース | `lib/infrastructure/repository/database/app_database.dart` | `AppDatabase`（`schemaVersion` は 5。4 から 5 へ上げるときに、このテーブルを作る） |
| 生成コード | `lib/infrastructure/repository/database/app_database.g.dart` | （drift が生成する。手で編集しない） |

## 使う箇所

- `lib/infrastructure/repository/operator_color/operator_color_repo.dart` の `OperatorColorRepo`: 色の読み書き（[PRC-021](../processes/PRC-021-list-operator-colors.md)〜[PRC-023](../processes/PRC-023-reset-operator-colors.md)）
- `lib/infrastructure/repository/settings/app_data_repo.dart` の `AppDataRepo`: バックアップの書き出し・読み込み・全削除（[backup-format.md](../../backup-format.md)）

## 項目一覧

物理テーブル名は `operator_colors`。

| 論理カラム名 | 物理カラム名 | データ型 | 桁数 | NotNull |
|---|---|---|---|---|
| 事業者名 | `operator_name` | TEXT | - | ◯ |
| 色 | `color` | INTEGER（不透明のARGB。`0xFFRRGGBB`） | - | ◯ |

- 事業者名は、[aggregation.md](../../aggregation.md) の「道路事業者の推定」の事業者名（NEXCO東日本、首都高速道路など）
- 色の透明度は、いつも不透明。保存するとき、透明度を不透明にそろえる
- 個人情報ではない（[privacy.md](../../privacy.md)）。端末内にだけ保存する

## キーと制約

- 主キー: `operator_name`。同じ事業者の色を選び直すと、置き換わる
- 事業者名が、事業者の表に無いときは、保存しない（[PRC-022](../processes/PRC-022-save-operator-color.md)）

## インデックス

主キー以外のインデックスは作らない（行数が最大9のため）。

## 関連するテスト

- 単体: `test/infrastructure/repository/operator_color/operator_color_repo_test.dart`（保存・置き換え・事業者順の読み出し・1件と全件の削除、4から5への更新で作られること）
- 単体: `test/infrastructure/repository/settings/app_data_repo_test.dart`（書き出し・置き換え・全削除に、色が含まれること）
