import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('routeOperatorOf', () {
    test('finds the operator by a word of the route name', () {
      const expected = {
        '首都高速4号新宿線': '首都高速道路',
        '阪神高速11号池田線': '阪神高速道路',
        '名古屋高速3号大高線': '名古屋高速道路公社',
        '福岡高速1号線': '福岡北九州高速道路公社',
        '北九州高速4号線': '福岡北九州高速道路公社',
        '広島高速3号線': '広島高速道路公社',
        '神戸淡路鳴門自動車道': '本州四国連絡高速道路',
        '東京湾アクアライン': 'NEXCO東日本',
        '東北縦貫自動車道弘前線': 'NEXCO東日本',
        '首都圏中央連絡自動車道': 'NEXCO東日本',
        '第一東海自動車道': 'NEXCO中日本',
        '中央自動車道富士吉田線': 'NEXCO中日本',
        '新湘南バイパス': 'NEXCO中日本',
        '山陽自動車道': 'NEXCO西日本',
        '九州横断自動車道長崎大分線': 'NEXCO西日本',
        '西名阪自動車道': 'NEXCO西日本',
      };
      for (final entry in expected.entries) {
        expect(routeOperatorOf(entry.key), entry.value, reason: entry.key);
      }
    });

    test(
      'takes the first operator of the table, as in docs/aggregation.md',
      () {
        // 中央 is a word of NEXCO中日本, but 首都高速 comes first.
        expect(routeOperatorOf('首都高速中央環状線'), '首都高速道路');
        // 瀬戸中央 is not NEXCO中日本's 中央.
        expect(routeOperatorOf('瀬戸中央自動車道'), '本州四国連絡高速道路');
      },
    );

    test('is null for a route the table does not know', () {
      expect(routeOperatorOf('箱根ターンパイク'), isNull);
      expect(routeOperatorOf(''), isNull);
    });
  });

  test('knows the operators of urban expressways', () {
    for (final operator in [
      '首都高速道路',
      '阪神高速道路',
      '名古屋高速道路公社',
      '福岡北九州高速道路公社',
      '広島高速道路公社',
    ]) {
      expect(isUrbanOperator(operator), isTrue, reason: operator);
    }
    for (final operator in [
      'NEXCO東日本',
      'NEXCO中日本',
      'NEXCO西日本',
      '本州四国連絡高速道路',
      multipleOperators,
      unknownOperator,
    ]) {
      expect(isUrbanOperator(operator), isFalse, reason: operator);
    }
  });

  group('operatorOfRoutes', () {
    test('is the operator when every known route has the same one', () {
      expect(operatorOfRoutes(['東名高速道路', '新東名高速道路']), 'NEXCO中日本');
      expect(operatorOfRoutes(['山陽自動車道']), 'NEXCO西日本');
    });

    test('ignores a route without an operator when another has one', () {
      expect(operatorOfRoutes(['箱根ターンパイク', '山陽自動車道']), 'NEXCO西日本');
    });

    test('is multiple when two operators are on the line', () {
      expect(operatorOfRoutes(['中央自動車道富士吉田線', '首都高速4号新宿線']), multipleOperators);
    });

    test('is unknown when no route is known', () {
      expect(operatorOfRoutes(const []), unknownOperator);
      expect(operatorOfRoutes(['箱根ターンパイク']), unknownOperator);
    });
  });
}
