# PRC-028 保存した地図の大きさの取得（GetTileCacheSizeUC）

## 概要

端末に保存している、地図のタイルの大きさ（バイト）を返す。設定画面の「保存した地図」に表示する。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/settings/get_tile_cache_size_uc.dart` | `GetTileCacheSizeUC` |
| 使う窓口（保存したタイル） | `lib/application/interface/tile_cache_if.dart` | `TileCacheIF`（`sizeInBytes`） |
| 窓口の実装 | `lib/infrastructure/repository/tile_cache/tile_cache_repo.dart` | `TileCacheRepo` |

## 呼び出し箇所

- [SCR-001](../screens/SCR-001-settings.md) の「保存した地図」の節（画面を開くたびと、タイルを消したあと）

## 入力

なし。

## 手順

1. `TileCacheIF` の `sizeInBytes` を呼ぶ
2. 実装は、タイルを保存しているフォルダ（アプリの保存領域の `fm_cache`）の中のファイルの大きさを、すべて足す。大きさの記録用のファイル（`sizeMonitor.bin`）は、含めない。フォルダが無い、または場所が分からないときは、0

## 出力

`int`（バイト。0以上）

## エラー時の動作

- 読み取りの失敗は、そのまま呼び出し元に返す。設定画面は、「保存した地図の大きさを調べられませんでした」を表示する

## 関連するテスト

- 単体: `test/infrastructure/repository/tile_cache/tile_cache_repo_test.dart`（大きさの合計、フォルダの中のフォルダ、記録用のファイルを数えないこと、フォルダが無いとき、場所が分からないとき）
- ウィジェット: `test/userinterface/settings/tile_cache_section_test.dart`（大きさの表示、読み取りの失敗）
