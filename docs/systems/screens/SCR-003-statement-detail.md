# SCR-003 利用明細詳細

## 概要

選んだ明細行の、すべての項目を表示する画面（[specification.md](../../specification.md) の 3.4）。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 画面 | `lib/userinterface/statements/statement_detail_screen.dart` | `StatementDetailScreen` |
| 画面の文言 | `lib/userinterface/statements/statement_detail_strings.dart` | `StatementDetailStrings` |
| 金額・日時の表示形式 | `lib/userinterface/common/format.dart` | `formatYen`、`formatDateTime` |
| ルートの地図 | `lib/userinterface/statements/line_route_map.dart` | `LineRouteMap` |
| 車両番号の入力 | `lib/userinterface/statements/vehicle_number_dialog.dart` | `showVehicleNumberDialog` |
| 入口日時・入口ICの入力 | `lib/userinterface/statements/entrance_dialogs.dart` | `showEntranceAtDialog`（初めの値を引数に取る）、`showEntranceIcDialog`（候補を引数に取る） |
| 使う処理の受け口 | `lib/userinterface/statements/statement_detail_providers.dart` | `getLineRouteUCProvider`、`lineRouteProvider` |

## 呼び出し箇所

- ルート `/statements/detail`（`lib/userinterface/app.dart` の `GoRouter`）。[SCR-002](SCR-002-statement-list.md) の OP-8 が、明細行（`StatementLineDTO`）を渡して開く。[SCR-005](SCR-005-route-map.md) の OP-8 は、同じ画面を `/route-map/detail` で開く

## 基本設計

### 画面イメージ

![SCR-003 利用明細詳細の画面イメージ](images/SCR-003-statement-detail.drawio.png)

### 入出力項目一覧

すべて出力。値は、渡された `StatementLineDTO` から表示する。ルートの地図だけは、[PRC-012](../processes/PRC-012-get-line-route.md) で取得する。

| 項目 | 型 | 表示形式 |
|---|---|---|
| ルートの地図 | `LineRouteDTO` | 項目の上に、高さ約240の地図。入口ICから出口ICまでの線（確定は実線、確認中は破線。間のICを通り、道路の形に沿った折れ線）と、入口・出口のマーカー（IC名。近似のときは「IC名（近似）」）を描き、マーカーと線のすべて（間のICを通る道のり、道路の形の点を含む）が収まるように表示する。入口が空欄で、線の始点が決まるときは、その始点にもマーカーを描く。地図の動かし方は、ピンチで拡大・縮小、ドラッグで移動。位置が分からないICがあるときは、地図の上に「位置が分からないICがあります: IC名」を示す。マーカーが1つも無いときは、地図を表示しない |
| タグ | `tags` | 「仕事・東京」（「・」でつなぐ）。無いときは「なし」。割引種別の次に表示する |
| メモ | `memo` | 利用者のメモ。無いときは「-」。タグの次 |
| メモ・タグを編集する行 | - | 保存済みの明細行のときだけ、「メモ・タグを編集」の行（鉛筆の印）を表示する。タップで OP-6 |
| 入口日時 | `entranceAt` | 「2026/01/10 08:30」。空欄のときは「-」と、「入力」ボタン |
| 出口日時 | `exitAt` | 「2026/01/10 09:15」 |
| 入口IC | `entranceIc` | 空欄のときは「-」と、「入力」ボタン |
| 出口IC | `exitIc` | IC名 |
| 通行した高速道路 | `routeNames` | 「東名高速道路・首都高速道路」のように「・」でつなぐ。無いときは「-」 |
| 距離（推定） | `LineRouteDTO.meters` | km で、小数1桁（`formatKm`）。入口ICから出口ICまでの道のりの推定（[aggregation.md](../../aggregation.md) の「距離の求め方」）。分からないとき、地図の取得中、取得に失敗したときは「-」 |
| 割引前料金 | `grossFare` | 「1,200円」。`null`（割引なし）のときは「-」 |
| ETC割引額 | `etcDiscount` | 「-240円」。`null`（割引なし）のときは「-」 |
| 通行料金 | `fare` | 「960円」 |
| 還元額適用料金 | `fareAfterRebate` | 「0円」 |
| 後納料金 | `postpaidFare` | 「960円」 |
| 車種 | `vehicleTypeName` | 名前（普通車、大型Ⅰなど。事業者の車種区分による。[vehicle-types.md](../../vehicle-types.md)） |
| 車両番号 | `vehicleNumber` | 数字（個人情報）。`null`（CSVで空欄）のときは「-」と、「入力」ボタン |
| 入口日時の入力 | 入力 | 日付の選択、時分の選択 | 「入力」で、日付の選択、続けて時分の選択を開く。初めの値は、入口日時の目安（[PRC-016](../processes/PRC-016-estimate-entrance-at.md)）。目安が無いときは、出口日時。目安を使うときは、選択の見出しに「（出口日時から計算した目安）」と出す。続けて、確認のダイアログ（下の「確認」）。出口日時より後のときは、ER-4 |
| 入口ICの入力 | 入力 | ダイアログ | 「入力」で開く。一覧から選ぶのが基本。上に、IC名で絞る欄。一覧は、「これまでに使った入口IC」（回数つき）、「同じ路線のIC」（路線名つき）、最後に「一覧にない場合は、自由に入力する」。選ぶと、「保存」を押せる。「自由に入力する」を選ぶと、IC名の入力欄が出る（空のときは「保存」を押せない）。「保存すると、あとから変更できません」の注意、「キャンセル」「保存」。一覧は、[PRC-020](../processes/PRC-020-list-entrance-candidates.md) で取得する。取得に失敗したときは、一覧なしで、自由入力だけを出す |
| 車両番号の入力 | 入力 | ダイアログ | 「入力」で開く。数字の入力欄（1〜4桁）、「保存すると、あとから変更できません」の注意、「キャンセル」「保存」。入力が1〜4桁の数字でないときは、「保存」を押せない |
| ETCカード番号 | `cardNumberSuffix` | 「**** 0001」（下4桁のみ） |
| 状態 | `status` | 「確定」または「確認中」 |
| 割引種別 | `discountTypes` | 「深夜割引・休日割引」のように「・」でつなぐ。無いときは「なし」 |

- 通行した高速道路（路線名）の決め方は、[route-map.md](../../route-map.md) の「路線名」に従う。決められないときは、[SCR-004](SCR-004-ic-mapping.md) で対応づけを登録すると、表示される

### 操作一覧

| 操作ID | 操作 | きっかけ | 動作 | 遷移先 |
|---|---|---|---|---|
| OP-1 | 戻る | 戻るボタン（画面上部、または端末の戻る操作） | 元の表示（一覧またはタイムライン）に戻る。絞り込みなどの状態は保たれる | [SCR-002](SCR-002-statement-list.md) |
| OP-3 | 車両番号を入力する | 「入力」のタップ（車両番号が空欄のときだけ） | 入力のダイアログを開く。「保存」で、車両番号を保存して、この画面の車両番号を更新する。一覧・ルートマップ・集計も、読み込み直させる（`dataRevisionProvider`）。「入力」は、保存したあとは出ない（再編集はできない） | なし |
| OP-4 | 入口日時を入力する | 入口日時の「入力」のタップ（入口日時が空欄のときだけ） | 入口日時の目安を求め（失敗したときは、目安なし）、日付と時分を選び、確認して、入口日時を保存し、この画面を更新する。保存したあと、ルートの地図、路線名、一覧・タイムライン・ルートマップ・集計も、読み込み直させる。「入力」は、保存したあとは出ない | なし |
| OP-6 | メモ・タグを編集する | 「メモ・タグを編集」のタップ（保存済みの明細行のときだけ） | 入力のダイアログ（メモ、タグ）を開く。メモは1〜3行の入力欄（200文字まで）。タグは、いまのタグを、消せる印つきで並べ、入力欄（20文字まで）で追加する（「追加」のタップか、Enter）。「これまでに使ったタグ」（ほかの明細行のタグ。このダイアログにまだ無いもの）を、タップで追加できる。タグは10個まで、`;` と改行は使えない（入力欄の下に理由を出す）。「保存」で、保存し（[PRC-027](../processes/PRC-027-save-line-note.md)）、一覧・ルートマップ・集計を更新させる（`dataRevisionProvider`）。「キャンセル」なら何もしない | なし |
| OP-5 | 入口ICを入力する | 入口ICの「入力」のタップ（入口ICが空欄のときだけ） | 候補を取得し（PRC-020）、一覧から入口ICを選ぶか、自由に入力して、保存する。OP-4 と同じように更新する | なし |
| OP-2 | ルートの地図を表示する | 画面を開く | 渡された明細行のルート（区間、マーカー、位置が分からないIC）を取得し、地図に描く。取得中は、地図の場所に読み込み中の表示を出す。ほかの項目は、取得を待たずに表示する | なし |

### エラー一覧

| ID | 発生する場面 | 表示する文言（文字列定数） | 操作の続け方 |
|---|---|---|---|
| ER-1 | 明細行が渡されずに開かれた（アプリの再起動後に、この画面の位置が復元されたときなど） | `StatementDetailStrings.notFound` | OP-1 で戻る |
| ER-4 | OP-4 で、選んだ入口日時が出口日時より後 | `StatementDetailStrings.entranceAfterExit`（画面下のメッセージで表示する） | 保存しない。もう一度「入力」から選ぶ |
| ER-5 | OP-6 の保存に失敗 | `StatementDetailStrings.saveNoteFailed`（画面下のメッセージで表示する） | もう一度保存する |
| ER-3 | OP-3、OP-4、OP-5 の保存に失敗（ほかの操作で既に車両番号が入っていた場合を含む） | `StatementDetailStrings.saveVehicleNumberFailed`（画面下のメッセージで表示する。失敗の詳細は出さない） | ダイアログは閉じる。もう一度「入力」から入力する（既に入っていれば、「入力」は出ない） |
| ER-2 | OP-2 で、ルートの取得に失敗 | `StatementDetailStrings.routeLoadFailed`（地図の場所に表示する。失敗の詳細は出さない） | ほかの項目は、そのまま見られる。画面を開き直すと、もう一度取得する |

## 詳細設計

- 項目の値は、SCR-002 または [SCR-005](SCR-005-route-map.md) から渡された `StatementLineDTO` を使う。OP-3 で車両番号を保存したときは、保存した値で、この画面の `StatementLineDTO` を作り直す
- OP-4 の初めの値は、`EstimateEntranceAtUC`（[PRC-016](../processes/PRC-016-estimate-entrance-at.md)）で求める
- OP-4・OP-5 は、`SaveEntranceUC`（[PRC-015](../processes/PRC-015-save-entrance.md)）を呼ぶ。入力できるのは、`StatementLineDTO.entranceAt`・`entranceIc` が `null` のときだけ（保存すると `null` でなくなるので、再編集はできない）。確認のダイアログは、車両番号と同じ「保存すると、あとから変更できません」
- OP-6 は、`SaveLineNoteUC`（[PRC-027](../processes/PRC-027-save-line-note.md)）を呼ぶ。「これまでに使ったタグ」は、利用明細一覧の読み込み結果（`StatementListDTO.tagChoices`。絞り込みの影響を受けない）から取る
- OP-3 は、`SaveVehicleNumberUC`（[PRC-014](../processes/PRC-014-save-vehicle-number.md)）を呼ぶ。車両番号を入力できるのは、`StatementLineDTO.vehicleNumber` が `null` のときだけ（保存すると `null` でなくなるので、再編集はできない）
- ルートの地図は、`GetLineRouteUC`（[PRC-012](../processes/PRC-012-get-line-route.md)）で取得する。地図の描き方（OpenStreetMapの地図、線の太さと色、マーカー、出典の表示）は、SCR-005 と同じ。SCR-005 と違い、線やマーカーのタップ、位置の指定はできない（位置の指定は SCR-005 で行う）
- 地図の取得は、ほかの項目の表示を止めない。ER-2 のときも、ほかの項目は表示する
- 車両番号とETCカード番号は個人情報。画面には出すが、ログには出さない（[privacy.md](../../privacy.md)）

## 関連するテスト

- 単体: `test/application/usecase/route_map/get_line_route_uc_test.dart`（PRC-012）
- ウィジェット: `test/userinterface/statements/statement_detail_screen_test.dart`（ルートの地図（線・マーカー、確認中の破線、位置が分からないICの表示、入口が空欄、マーカーが無いとき地図が出ないこと、読み込み中、ER-2）、すべての項目（路線名を含む）の表示、空欄・`null`・路線名なしの項目が「-」になること、割引種別が無いとき「なし」、確認中、明細行が渡されないときのER-1、戻るボタン）
- ウィジェット: 入口日時・入口ICの入力（入口日時の初めの値が目安になること、目安が無いとき出口日時になること、「入力」が出る条件、日付と時分の選択、確認、保存で画面が更新されること、出口より後のER-4、キャンセル、保存の失敗）、車両番号の入力（「入力」が出る条件、数字の検証、保存で画面が更新されること、キャンセル、保存の失敗ER-3）は、同じファイル
- 結合: `integration_test/statement_list_test.dart`（一覧から詳細を開け、ルートの地図が出ること）
- 結合: `integration_test/vehicle_number_test.dart`（車両番号が空欄のCSVを取り込み、詳細で入力して、保存されること。入口日時・入口ICが空欄の行に入力しても、CSVの値と重複判定のキーが変わらないこと。再取り込みで、別の行として増えず、入力した値が消えないこと）
