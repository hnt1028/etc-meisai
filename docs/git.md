# Git運用方針

言語と品質ゲートは [CLAUDE.md](../CLAUDE.md) に従う。ここには Git 固有のルールだけを書く。

## リポジトリ

- リモート: `origin` = https://github.com/hnt1028/etc-meisai.git
- 既定ブランチ: `master`（変更しない）
- `develop` は `master` から作成する

## ブランチ構成

| ブランチ | 用途 | 切る元 | マージ先 |
|---|---|---|---|
| `master` | リリース済みの状態 | - | - |
| `develop` | 次のリリースに向けた統合 | `master` | - |
| `rule` | ルール（CLAUDE.md / docs）の変更 | `master` | `master`（その後 `develop` へ取り込む） |
| `feature` | 機能追加 | `develop` | `develop` |
| `<担当者名>` | `feature` 上での個人作業 | `feature` | `feature` |
| `fix` | バグ修正 | `develop` | `develop` |
| `release` | リリース作業（バージョン表記の変更） | `develop` | `master`（その後 `develop` へ取り込む） |

### ブランチ名

- `種別/内容` の形式（例: `feature/csv-import`、`fix/duplicate-check`、`rule/git-policy`）
- `<担当者名>` ブランチは `<担当者名>/内容` の形式（例: `<担当者名>/csv-parser`）
- `<担当者名>` は `git config --global mtrk.owner` の値を使う。未設定の場合は、担当者に次のコマンドで設定してもらう。Claude が名前を決めない

  ```bash
  git config --global mtrk.owner <担当者名>
  ```

- 英小文字とハイフンのみを使う

## コミット

- 1つの変更につき1コミット。例外なし
- コミットは必ず署名する（署名のない コミットは作らない）
- コミットはユーザーが依頼したときにのみ行う
- メッセージは `{種別}: {変更内容}` の形式。種別は `Add` / `Update` / `Remove` / `Fix` / `Change` のいずれか

  例: `Add: 利用明細CSVのパーサーを追加`

- 本文は必要なときだけ、変更の理由を書く
- 末尾に次の行を付ける（実際に使ったモデル名に合わせる）

  ```
  Co-Authored-By: Claude Haiku 5.5 <noreply@anthropic.com>
  ```

## マージ

- マージは Pull Request 経由で、Fast-forward のみ（`git merge --ff-only`）
- `master` への変更は `release` と `rule` のマージだけ
- マージ前に CLAUDE.md の完了条件を通す（GitHub Actions で確認）
- PRの本文は `.github/pull_request_template.md` に従う
- PRのレビューはユーザーと Claude が行う
- マージ後、作業ブランチは削除する

## 手順

- `release`: `develop` から切り、バージョン表記（`pubspec.yaml` など）を変更してコミット（`Change: バージョンを x.y.z に変更`）。`master` にマージし、`develop` へ取り込む
- `rule`: `master` から切り、ルールを変更してコミット。`master` にマージし、`develop` へ取り込む

## .gitignore

- 実際の利用明細CSV（データ用フォルダ全体、またはCSVファイル全般）を除外する。個人情報の扱いは [privacy.md](privacy.md) に従う
- 端末内DBやキャッシュファイルを除外する
- Flutterのビルド生成物（`build/`、`.dart_tool/` など）を除外する

## 禁止事項

- `master` / `develop` への force push
