# アーキテクチャ

アプリは4つの層と、3種類のデータ型（Entity、Value、DTO）で構成する。依存は一方向だけ。

## 各層の役割

| 層 | ディレクトリ | 役割 |
|---|---|---|
| Userinterface | `lib/userinterface/` | 画面と表示。Flutterのウィジェットを置く。業務の判断はしない |
| Usecase | `lib/usecase/` | 画面から呼ばれる業務処理（取り込み、絞り込み、合計計算など）。Entity から DTO を作る。Flutterに依存しない |
| Interface | `lib/interface/` | Usecaseが使う保存・取得の窓口を定めた抽象クラス。実装は Repository が持つ |
| Repository | `lib/repository/` | Interfaceの実装。drift（DB）、CSVパーサー、地図タイルの取得など。Entityを作る |

## データ型

| 種類 | ディレクトリ | 作る主体 | 役割 |
|---|---|---|---|
| Entity | `lib/domain/entity/` | Repository | 業務の対象（利用 `TripEntity` など）。値を保存するだけ |
| Value | `lib/domain/value/` | - | 列挙型のデータ（確定・確認中など）。他に依存しない |
| DTO | `lib/application/dto/` | Usecase | 画面に渡すデータ。表示に必要な値だけを持つ |

- Entity は値を保存するだけで、メソッドを定義しない。計算や判定は Usecase に置く
- Entity は Value を使ってよい（例: `TripEntity` の状態に `ConfirmationStatusValue` を持つ）
- DTO は Entity に依存しない。Entity の値は Usecase が DTO に詰め替える
- DTO は値を保存するだけで、メソッドを定義しない
- ETCカード番号のマスクなど、画面に出す形の加工は Usecase で行い、DTO に入れる
- Value は列挙型に限る。値を持つだけの型は Entity か DTO として扱う

## 依存の規則

- Userinterface は Usecase と DTO に依存する。Entity と Repository を直接使わない
- Usecase は Interface、Entity、DTO、Value に依存する。Repository と Flutter に依存しない
- Repository は Interface、Entity、Value に依存する
- Interface は Entity と Value に依存してよいが、他の層には依存しない
- Entity は Value にだけ依存する
- DTO は Value にだけ依存する
- Value は他に依存しない
- 層をまたぐ依存（例: Userinterface から Repository の import）は禁止する
- 依存の組み立て（Repository を Usecase に渡すこと）は `lib/main.dart` の1か所で行う

## 命名

クラスがどの層・種類に属するかが名前で分かるように、クラス名とファイル名の末尾に次の接尾辞を付ける。

| 種類 | クラス名の接尾辞 | ファイル名の接尾辞 | 例 |
|---|---|---|---|
| Entity | `Entity` | `_entity` | `TripEntity` / `trip_entity.dart` |
| Value | `Value` | `_value` | `ConfirmationStatusValue` / `confirmation_status_value.dart` |
| DTO | `DTO` | `_dto` | `TripDTO` / `trip_dto.dart` |
| Interface | `IF` | `_if` | `TripIF` / `trip_if.dart` |
| Repository | `Repo` | `_repo` | `TripRepo` / `trip_repo.dart` |
| Usecase | `UC` | `_uc` | `ImportStatementUC` / `import_statement_uc.dart` |

- 語幹は [ubiquitous-language.md](ubiquitous-language.md) の英語に従う（`Trip` → `TripEntity`）
- Interface と、それを実装する Repository は、接尾辞を除いた語幹を同じにする（`TripIF` を実装するのは `TripRepo`）。実装を差し替えるときは `TripRepo` を置き換え、別名の実装を並べない
- Userinterface の命名は、ここでは定めない

## ディレクトリ内の分け方

- Userinterface、Usecase、Repository の中は、機能ごとにサブディレクトリを分ける（`statements/`、`route_map/`、`settings/`）
- Entity、Value、DTO は機能ごとに分けず、種類ごとに1つのディレクトリに置く
- 機能名は [specification.md](specification.md) の画面に対応させる

## テスト

- Usecase と Repository は、単体テストの対象にする（[testing.md](testing.md)）
- Repository のテストは、Interface（抽象クラス）の定めた動作どおりになることを確認する
- Userinterface は、ウィジェットテストと結合テストの対象にする
