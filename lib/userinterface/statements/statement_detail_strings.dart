/// Every text of the statement detail screen.
/// Design: docs/systems/screens/SCR-003-statement-detail.md
abstract final class StatementDetailStrings {
  static const title = '利用明細詳細';

  static const entranceAt = '入口日時';
  static const exitAt = '出口日時';
  static const entranceIc = '入口IC';
  static const exitIc = '出口IC';
  static const routeNames = '通行した高速道路';
  static const distance = '距離（推定）';
  static const grossFare = '割引前料金';
  static const etcDiscount = 'ETC割引額';
  static const fare = '通行料金';
  static const fareAfterRebate = '還元額適用料金';
  static const postpaidFare = '後納料金';
  static const vehicleType = '車種';
  static const vehicleNumber = '車両番号';
  static const cardNumber = 'ETCカード番号';
  static const status = '状態';
  static const discountTypes = '割引種別';

  static const blank = '-';
  static const none = 'なし';
  static const confirmed = '確定';
  static const pending = '確認中';

  /// Shows only the last 4 characters of the card number.
  static String cardNumberValue(String suffix) => '**** $suffix';

  static const notFound = '明細行が見つかりません';

  static const vehicleNumberEnter = '入力';
  static const vehicleNumberDialogTitle = '車両番号を入力';
  static const vehicleNumberInputLabel = '車両番号（1〜4桁の数字）';
  static const vehicleNumberOnceNotice = enteredOnceNotice;
  static const enteredOnceNotice = '保存すると、あとから変更できません';

  static const entranceAtPickDate = '入口の日付';
  static const entranceAtPickTime = '入口の時刻';
  static const entranceAtPickDateEstimated = '入口の日付（出口日時から計算した目安）';
  static const entranceAtPickTimeEstimated = '入口の時刻（出口日時から計算した目安）';
  static const entranceAtDialogTitle = '入口日時を保存';
  static const entranceIcDialogTitle = '入口ICを選ぶ';
  static const entranceIcInputLabel = '入口IC（自由入力）';
  static const entranceIcFilterLabel = 'IC名で絞り込む';
  static const entranceIcUsedHeader = 'これまでに使った入口IC';
  static const entranceIcSameRouteHeader = '同じ路線のIC';
  static const entranceIcFreeInput = '一覧にない場合は、自由に入力する';
  static const entranceIcNoMatch = '当てはまるICがありません';

  /// The number of times an IC was the entrance with the same exit.
  static String entranceIcUses(int uses) => '同じ出口で $uses回';
  static const entranceAfterExit = '入口日時は、出口日時より前にしてください';
  static const cancel = 'キャンセル';
  static const save = '保存';
  static const saveVehicleNumberFailed = '保存できませんでした';

  /// Above the map, when a position is not known.
  static String unlocatedNotice(List<String> icNames) =>
      '位置が分からないICがあります: ${icNames.join('、')}';

  static const routeLoadFailed = 'ルートを取得できませんでした';
}
