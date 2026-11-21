# PRC-029 保存した地図の削除（ClearTileCacheUC）

## 概要

端末に保存している、地図のタイルを、すべて消す。消したタイルは、その場所をもう一度見たとき、取得し直して、また保存される。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/settings/clear_tile_cache_uc.dart` | `ClearTileCacheUC` |
| 使う窓口（保存したタイル） | `lib/application/interface/tile_cache_if.dart` | `TileCacheIF`（`clear`） |
| 窓口の実装 | `lib/infrastructure/repository/tile_cache/tile_cache_repo.dart` | `TileCacheRepo` |

## 呼び出し箇所

- [SCR-001](../screens/SCR-001-settings.md) の OP-11（保存した地図を消す）

## 入力

なし。

## 手順

1. `TileCacheIF` の `clear` を呼ぶ
2. 実装は、タイルを保存しているフォルダの中のファイルを、すべて消す。大きさの記録用のファイル（`sizeMonitor.bin`）は、残す。フォルダが無い、または場所が分からないときは、何もしない

## 出力

- なし（完了したら戻る）

## エラー時の動作

- 削除の失敗は、そのまま呼び出し元に返す。設定画面は、「消せませんでした」を表示する

## 補足

- 地図のタイルの保存は、`flutter_map` の機能が行う。このUCは、その保存フォルダのファイルを直接消す。使っている最中のタイルを消しても、そのタイルは取得し直されるだけ（壊れたタイルは、取得し直す）
- 大きさの記録用のファイルは、消したタイルの分が引かれないため、記録は、実際より大きいままになる。記録が上限（1GB）を超えると、`flutter_map` が、古いタイルを消す。保存した地図が少ないのに消されることは、通常はない

## 関連するテスト

- 単体: `test/infrastructure/repository/tile_cache/tile_cache_repo_test.dart`（消すこと、記録用のファイルが残ること、フォルダが無いとき）
- ウィジェット: `test/userinterface/settings/tile_cache_section_test.dart`（確認のあと消すこと、キャンセル、削除の失敗）
