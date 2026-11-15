/// Every text of the statement detail screen.
/// Design: docs/systems/screens/SCR-003-statement-detail.md
abstract final class StatementDetailStrings {
  static const title = '利用明細詳細';

  static const entranceAt = '入口日時';
  static const exitAt = '出口日時';
  static const entranceIc = '入口IC';
  static const exitIc = '出口IC';
  static const routeNames = '通行した高速道路';
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
}
