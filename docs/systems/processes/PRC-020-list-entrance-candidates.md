# PRC-020 入口ICの候補の取得（ListEntranceCandidatesUC）

## 概要

入口ICが空欄の明細行に、入口ICを入力するときの、選択肢（候補）を返す。入口ICの入力は、1回だけで、あとから変えられない。そのため、自由入力だけにせず、一覧から選べるようにする。一覧には、利用者がこれまでに使った入口ICと、出口と同じ路線のICを出す。仕様は [specification.md](../../specification.md) の3.4。

## 実装箇所

| 役割 | ファイル | クラス |
|---|---|---|
| 処理本体 | `lib/application/usecase/statements/list_entrance_candidates_uc.dart` | `ListEntranceCandidatesUC` |
| 結果の受け渡し | `lib/application/dto/entrance_candidates_dto.dart` | `EntranceCandidatesDTO`、`EntranceCandidateDTO` |
| 使う窓口（明細行の取得） | `lib/application/interface/statement_line_if.dart` | `StatementLineIF`（`findAll`） |
| 使う窓口（ICマスタ） | `lib/application/interface/ic_master_if.dart` | `IcMasterIF`（`findAll`） |
| 使う窓口（ICの対応づけ） | `lib/application/interface/ic_mapping_if.dart` | `IcMappingIF`（`findAll`） |
| 使う窓口（ICの位置） | `lib/application/interface/ic_position_if.dart` | `IcPositionIF`（`findAll`） |
| 使う部品（IC名の照合） | `lib/application/usecase/ic_mapping/ic_lookup.dart` | `IcLookup`（`resolve`、`routeNamesOf`） |
| 使う部品（直線距離） | `lib/application/usecase/aggregation/ic_distance.dart` | `IcDistance.straightMeters` |

## 呼び出し箇所

- [SCR-003](../screens/SCR-003-statement-detail.md) の OP-5（入口ICを入力する）が、ダイアログを開く前に呼び出す

## 入力

| 名前 | 型 | 意味 |
|---|---|---|
| `line` | `StatementLineDTO` | 詳細を表示している明細行（入口ICが空欄のもの） |

## 手順

1. `StatementLineIF`、`IcMasterIF`、`IcMappingIF`、`IcPositionIF` の `findAll` で、明細行、ICマスタ、対応づけ、位置の指定を取得し、`IcLookup` を作る
2. **利用したIC**: すべての明細行の入口IC（CSVの値と、利用者が入力した値。空欄を除く）を、IC名ごとに数える。出口が `line` と同じ明細行での回数も数える。並びは、同じ出口での回数が多い順、全体の回数が多い順、IC名の順
   - 路線名は、`IcLookup` の `routeNamesOf`（入口に、そのIC名、出口に、`line` の出口IC）で決める。分からないときは空
3. **同じ路線のIC**: `line` の出口ICが、ICマスタの地点に決まるとき、その地点と同じ路線名を1つでも持つ地点を集める
   - 種別が一般IC、スマートIC、その他（料金所など）のもの。JCT は入口にならないため、除く
   - 出口の地点そのもの、および、手順2で出たIC名と同じ地点（`IcLookup` の `resolve` で、地点が同じ）は除く。同じ名前の地点は、1つにする
   - 並びは、出口の地点からの直線距離が近い順（同じなら名前の順）
   - 出口ICが地点に決まらないとき（利用者が位置だけ指定したときを含む）は、空
4. 2 と 3 を `EntranceCandidatesDTO` にして返す

## 出力

`EntranceCandidatesDTO`

| フィールド | 型 | 意味 |
|---|---|---|
| `used` | `List<EntranceCandidateDTO>` | 手順2の、利用したIC |
| `sameRoute` | `List<EntranceCandidateDTO>` | 手順3の、同じ路線のIC |

`EntranceCandidateDTO`

| フィールド | 型 | 意味 |
|---|---|---|
| `icName` | `String` | IC名。利用したICはCSVの表記のまま、同じ路線のICはマスタの名前 |
| `routeNames` | `List<String>` | 路線名。無いときは空 |
| `uses` | `int` | その出口で、入口として使った回数（同じ路線のICは 0） |

## エラー時の動作

- 読み取りの失敗（`StatementLineIF` など）は、そのまま呼び出し元に返す。呼び出し元（画面）は、候補なしとして、自由入力だけのダイアログを開く（入力をふさがない）

## 関連するテスト

- 単体: `test/application/usecase/statements/list_entrance_candidates_uc_test.dart`（利用したICの数え方と並び、同じ出口の回数、同じ路線のICの絞り込み・並び、JCTと出口と重複の除外、出口が地点に決まらないとき、明細行が無いとき、読み取りの失敗）
