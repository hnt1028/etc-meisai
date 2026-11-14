/// Whether the amount of a trip is final.
enum ConfirmationStatusValue {
  /// The amount is final (備考: 確定).
  confirmed,

  /// Discounts or closures are not yet reflected (備考: 確認中).
  pending,
}
