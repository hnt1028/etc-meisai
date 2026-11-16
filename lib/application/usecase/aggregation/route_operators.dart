/// Road operators found from route names. The table is in
/// docs/aggregation.md ("道路事業者の推定"): change both together.
///
/// It is an estimate: N06 and the CSV have no operator.
const _operators = <(List<String>, String)>[
  (['首都高速'], '首都高速道路'),
  (['阪神高速'], '阪神高速道路'),
  (['名古屋高速'], '名古屋高速道路公社'),
  (['福岡高速', '北九州高速'], '福岡北九州高速道路公社'),
  (['広島高速'], '広島高速道路公社'),
  (['神戸淡路鳴門', '西瀬戸', '瀬戸中央'], '本州四国連絡高速道路'),
  (
    [
      '東京湾アクアライン',
      '東北',
      '常磐',
      '関越',
      '東関東',
      '北関東',
      '館山',
      '磐越',
      '上信越',
      '日本海東北',
      '秋田',
      '山形',
      '三陸',
      '北海道',
      '道央',
      '道東',
      '札樽',
      '外環',
      '京葉',
      '圏央道',
      '首都圏中央',
    ],
    'NEXCO東日本',
  ),
  (
    [
      '東名',
      '第一東海',
      '第二東海',
      '新東名',
      '中央',
      '長野',
      '東海北陸',
      '伊勢湾岸',
      '東海環状',
      '中部横断',
      '新湘南',
      '能越',
      '北陸',
      '名神',
      '新名神',
    ],
    'NEXCO中日本',
  ),
  (
    [
      '近畿',
      '山陽',
      '中国',
      '九州',
      '長崎',
      '大分',
      '宮崎',
      '東九州',
      '関門',
      '西九州',
      '松山',
      '高知',
      '徳島',
      '高松',
      '四国',
      '阪和',
      '関西空港',
      '京都縦貫',
      '舞鶴若狭',
      '西名阪',
      '第二神明',
    ],
    'NEXCO西日本',
  ),
];

/// What an aggregation calls a line that runs on the roads of two or more
/// operators, and one whose operator is not known.
const multipleOperators = '複数の事業者';
const unknownOperator = '不明';

/// The operator of one route, or null when the table does not know it.
String? routeOperatorOf(String routeName) {
  for (final (words, operator) in _operators) {
    if (words.any(routeName.contains)) return operator;
  }
  return null;
}

/// The operator of a statement line with these routes: the operator when all
/// the routes that are known have the same one, [multipleOperators] when they
/// have two or more, and [unknownOperator] when none is known.
String operatorOfRoutes(Iterable<String> routeNames) {
  final known = {for (final name in routeNames) ?routeOperatorOf(name)};
  if (known.isEmpty) return unknownOperator;
  if (known.length == 1) return known.single;
  return multipleOperators;
}
