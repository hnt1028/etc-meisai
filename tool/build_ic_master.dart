// Makes assets/ic_master.json from the GeoJSON of N06. See docs/route-map.md.
//
//   dart run tool/build_ic_master.dart <folder of the N06 GeoJSON> <OSM JSON> <OSM roads JSON> assets/ic_master.json
import 'dart:convert';
import 'dart:io';

import 'ic_master_builder.dart';

const _source =
    '国土交通省 国土数値情報（高速道路時系列データ N06-25）'
    '（https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-N06-2025.html）を加工して作成。'
    '一部の料金所・出入口の位置と、東京湾アクアラインの道路の形は © OpenStreetMap contributors（ODbL）';

void main(List<String> args) {
  if (args.length != 4) {
    stderr.writeln(
      'usage: dart run tool/build_ic_master.dart <N06 GeoJSON folder> <OSM JSON> <OSM roads JSON> <output>',
    );
    exit(64);
  }
  final folder = args[0];
  final master = buildIcMaster(
    jointJson: File('$folder/N06-25_Joint.geojson').readAsStringSync(),
    sectionJson: File(
      '$folder/N06-25_HighwaySection.geojson',
    ).readAsStringSync(),
    osmJson: File(args[1]).readAsStringSync(),
    osmRoadsJson: File(args[2]).readAsStringSync(),
    source: _source,
  );
  // One point per line, so that a new master makes a readable diff.
  final points = master['points'] as List;
  final buffer = StringBuffer('{\n')
    ..writeln('"source": ${jsonEncode(master['source'])},')
    ..writeln('"points": [')
    ..writeln(points.map(jsonEncode).join(',\n'))
    ..writeln('],')
    ..writeln('"links": [')
    ..writeln((master['links'] as List).map(jsonEncode).join(',\n'))
    ..writeln(']')
    ..writeln('}');
  File(args[3]).writeAsStringSync(buffer.toString());
  stdout.writeln(
    'wrote ${points.length} points and ${(master['links'] as List).length} '
    'links to ${args[3]}',
  );
}
