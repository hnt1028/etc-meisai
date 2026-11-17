# ETC利用明細ビューア

ETC利用照会サービスの「利用明細CSV」をインポートし、利用明細の確認とルート表示ができるスマホアプリ（Flutter）。

## このファイルの運用ルール

- **CLAUDE.md は短く保つ（最大200行）。長いと正しく読み込まれなくなる**
- 文章量が増えたトピックは `docs/<トピック>.md` に切り出し、ここには1行の要約と参照だけ残す
- ルールは人間も読むため `docs/` に置く（`.claude/` には置かない）

## 言語

- ドキュメント、UI文言、コミットメッセージ、PR説明、ユーザーへの返答は日本語
- コード内のコメントと識別子は英語

## 仕様

画面を含む振る舞いは [docs/specification.md](docs/specification.md) に従う。画面の追加は要件変更なので要確認。

## 技術スタック

Flutter / Riverpod / go_router / drift(SQLite) / flutter_map。Android優先。パッケージは導入時に最新版を確認し、`pubspec.yaml` を正とする。React Native等への変更は先にユーザーへ確認する。

## 基本ルール

- データ取得は利用者によるCSVインポートのみ。ETCサービスへの自動ログイン・スクレイピングはしない
- 金額は `int`（円）。`double` は使わない
- 実装は `Userinterface` → `Usecase` → `Interface` ← `Repository` の4層と、`Entity`（Repositoryが作る）・`Value`（列挙型）・`DTO`（Usecaseが作り、画面に渡す）で行う。依存は一方向（詳細とレイヤー図は [docs/architecture.md](docs/architecture.md)）
- 要件が曖昧なときは推測で進めず質問する。依頼外の機能追加や大規模リファクタをしない
- 完了を報告する前に、変更したファイルを読み直して確認する。確認していない項目は「完了」と書かない（文書なら表の列数・リンク先・旧名の残存など）
- コミット・ブランチ・マージの規則は [docs/git.md](docs/git.md) に従う
- UI文言は文字列定数にまとめる
- 完了条件: `dart format --set-exit-if-changed .` / `flutter analyze` / `flutter test`（単体・ウィジェット）/ 結合テストがすべて通る
- 実装時は単体テストと結合テストを行う（詳細は [docs/testing.md](docs/testing.md)）
- 実装時は設計書を画面・処理・テーブルごとに作成し、台帳でIDを管理する（詳細は [docs/systems.md](docs/systems.md)）

## 詳細ルール（`docs/`）

該当する作業の前に、対応するファイルを必ず読むこと。

- [docs/privacy.md](docs/privacy.md): 個人情報の扱い。コードを書く前に常に確認
- [docs/csv-format.md](docs/csv-format.md): CSVの列仕様、パース、重複判定。取込・DB周りの作業時
- [docs/route-map.md](docs/route-map.md): ICの座標マスタとルート描画。地図画面の作業時
- [docs/specification.md](docs/specification.md): 仕様書。画面や振る舞いを変えるとき、実装と同時に更新する
- [docs/architecture.md](docs/architecture.md): 4層のアーキテクチャ（各層の役割と依存の規則）。実装の前に確認
- [docs/systems.md](docs/systems.md): 設計書（画面・処理・テーブル）の作り方、IDの付け方、台帳。実装時に確認
- [docs/vehicle-types.md](docs/vehicle-types.md): 車種区分（車種番号の名前が事業者ごとに違う）のマスタと、名前の決め方。車種を扱う作業時
- [docs/testing.md](docs/testing.md): テスト方針（単体・ウィジェット・結合）。テストを書くとき
- [docs/git.md](docs/git.md): ブランチ、コミット、マージ、PRの運用。Git操作の前に確認
- [docs/ubiquitous-language.md](docs/ubiquitous-language.md): ユビキタス言語（日本語と英語の対応）。名前を付けるときに確認
