/// The colors of the lines on the roads of each operator, until the user
/// chooses another (docs/route-map.md, "線の色"), as opaque ARGB numbers.
/// One for each operator of the route operators table.
///
/// NEXCO: the colors of the logos (ネクスコグリーン / オレンジ / ブルー).
/// 首都高: read from the logo. 福岡北九州 (黄緑), 広島 (桃) and 本四 (藍): told by
/// the user; 本四 is deep, to be told from NEXCO西日本. 阪神 (a red) and 名古屋
/// (a purple) are not the colors of their logos: those were too close to other
/// operators to be told apart on the map.
const defaultOperatorColors = <String, int>{
  'NEXCO東日本': 0xFF2E9E4F,
  'NEXCO中日本': 0xFFF08300,
  'NEXCO西日本': 0xFF1E7FD8,
  '首都高速道路': 0xFF1490A8,
  '阪神高速道路': 0xFFD32F2F,
  '名古屋高速道路公社': 0xFF8E24AA,
  '福岡北九州高速道路公社': 0xFF8BC34A,
  '広島高速道路公社': 0xFFF06292,
  '本州四国連絡高速道路': 0xFF1A2A80,
};
