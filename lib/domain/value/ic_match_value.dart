/// Whether an IC name of the CSV is tied to one IC point.
enum IcMatchValue {
  /// Exactly one IC point fits the name.
  matched,

  /// Two or more IC points fit the name. The user chooses one.
  ambiguous,

  /// No IC point fits the name. The user searches for one.
  unknown,

  /// The user registered the IC point for the name.
  registered,
}
