# バックアップファイルの形式

設定画面（[SCR-001](systems/screens/SCR-001-settings.md)）の「データを書き出す」「データを読み込む」で使うファイルの形式を定める。書き出し・読み込みの処理は、[PRC-017](systems/processes/PRC-017-export-data.md)、[PRC-018](systems/processes/PRC-018-import-data.md)。

## 対象

端末内に保存した、すべてのデータ。

| データ | 保存先 | 内容 |
|---|---|---|
| 明細行 | [TBL-001](systems/tables/TBL-001-statement-lines.md) | 取り込んだ明細行。利用者が入力した車両番号・入口日時・入口ICも含む。CSVの値と入力した値は、別々のまま書き出す（重複判定のキーが変わらないように） |
| ICの対応づけ | [TBL-002](systems/tables/TBL-002-ic-mappings.md) | 利用者が登録した、IC名とICマスタの地点の対応 |
| ICの位置の指定 | [TBL-003](systems/tables/TBL-003-ic-positions.md) | 利用者が地図で指定した、IC名の位置 |

ICマスタ（アプリに同梱）、画面の絞り込み・表示の選択は、対象外（保存していない、またはアプリに含まれている）。

## ファイル

- 文字コードは UTF-8、形式は JSON（拡張子 `.json`）
- ファイル名は、`etc-meisai-backup-年月日-時分.json`（例: `etc-meisai-backup-20261116-1234.json`）。書き出すときに、保存先の選択で変えられる
- **車両番号・ETCカード番号などの個人情報が、暗号化されずに入る**。ファイルの保管に注意する（[privacy.md](privacy.md)）

## 中身

```json
{
  "format": "etc-meisai-backup",
  "version": 1,
  "exportedAt": "2026-11-16T12:34:56.000",
  "statementLines": [
    {
      "id": "…",
      "duplicateKey": "…",
      "entranceAt": "2026-01-10T08:30:00.000",
      "exitAt": "2026-01-10T09:15:00.000",
      "entranceIc": "テスト北ＩＣ",
      "exitIc": "テスト東ＩＣ",
      "grossFare": 1200,
      "etcDiscount": -240,
      "fare": 960,
      "fareAfterRebate": 0,
      "postpaidFare": 960,
      "vehicleType": 1,
      "vehicleNumber": 1234,
      "enteredEntranceAt": null,
      "enteredEntranceIc": null,
      "cardNumber": "…",
      "status": "confirmed",
      "discountTypes": ["深夜割引"]
    }
  ],
  "icMappings": [{ "icName": "…", "pointId": "…" }],
  "icPositions": [{ "icName": "…", "latitude": 35.1, "longitude": 139.1 }]
}
```

- `format` は、必ず `etc-meisai-backup`
- `version` は、形式の版（いまは 1）。形式を変えたときに上げる。読み込むときは、アプリが知っている版より大きいと、エラーにする
- 日時は、ISO 8601（タイムゾーンなし。端末の時刻）
- `statementLines` の項目は、TBL-001 の列と同じ。`null` を許す項目は、`entranceAt`、`entranceIc`、`grossFare`、`etcDiscount`、`vehicleNumber`、`enteredEntranceAt`、`enteredEntranceIc`。`status` は `confirmed`（確定）か `pending`（確認中）。`vehicleType` は、CSVの車種の番号（1〜5）。`discountTypes` は、文字の並び（無いときは空）
- 並び順は、意味を持たない（読み込み後は、画面が並べ直す）

## 読み込みの検査

読み込むとき、次をすべて確かめる。1つでも合わなければ、何も置き換えない（[PRC-018](systems/processes/PRC-018-import-data.md)）。

- JSON として読めること。`format` と `version` が合うこと
- `statementLines`、`icMappings`、`icPositions` が、あること（空の並びでよい）
- 各項目の型（文字・整数・実数・日時・`null`）が合うこと。`vehicleType` と `status` が、決まった値であること
- `statementLines` の `id` と `duplicateKey`、`icMappings` と `icPositions` の `icName` が、それぞれ重複しないこと
- 緯度は -90〜90、経度は -180〜180

エラーの文面には、ファイルの値（個人情報を含む）を出さない。何件目の、どの項目かだけを示す。
