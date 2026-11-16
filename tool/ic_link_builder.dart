import 'dart:math' as math;

/// A point of the IC master that gets links.
class LinkPoint {
  const LinkPoint(this.id, this.latitude, this.longitude);

  final String id;
  final double latitude;
  final double longitude;
}

/// How far a point may be from the road network to be put on it.
const linkSnapMeters = 150.0;

/// The roads are cut into pieces of at most this length.
const _pieceMeters = 100.0;

/// Coordinates within this many degrees (about 20 m) are one vertex, so that
/// the ends of two routes meet at a junction.
const _cellDegrees = 2e-4;

/// Finds the points that are next to each other along the roads, and the
/// length of the road between them. See docs/route-map.md ("リンクの作り方").
///
/// [lines] are the lines of the route sections: each is a list of
/// `[longitude, latitude]`. A link is `[idA, idB, meters]`, with the ids in
/// order and one link for a pair.
List<List<Object>> buildIcLinks({
  required Iterable<List<List<double>>> lines,
  required List<LinkPoint> points,
}) {
  final network = _Network();
  for (final line in lines) {
    for (var i = 0; i + 1 < line.length; i++) {
      network.addSegment(line[i], line[i + 1]);
    }
  }

  // Put each point on the nearest vertex.
  final pointsAt = <int, List<int>>{};
  for (var i = 0; i < points.length; i++) {
    final vertex = network.nearestVertex(
      points[i].longitude,
      points[i].latitude,
      linkSnapMeters,
    );
    if (vertex != null) pointsAt.putIfAbsent(vertex, () => []).add(i);
  }

  final links = <String, List<Object>>{};
  void link(int a, int b, double meters) {
    final idA = points[a].id, idB = points[b].id;
    final ordered = idA.compareTo(idB) <= 0 ? [idA, idB] : [idB, idA];
    final key = '${ordered[0]}\u0000${ordered[1]}';
    final rounded = meters.round();
    final known = links[key];
    if (known == null || (known[2] as int) > rounded) {
      links[key] = [ordered[0], ordered[1], rounded];
    }
  }

  // Points on one vertex are at the same place.
  final owners = <int, int>{};
  pointsAt.forEach((vertex, indexes) {
    owners[vertex] = indexes.first;
    for (var i = 1; i < indexes.length; i++) {
      link(indexes[0], indexes[i], 0);
    }
  });

  // The nearest point (by road) of every vertex, from all the points at once.
  final distance = List<double>.filled(network.count, double.infinity);
  final owner = List<int>.filled(network.count, -1);
  final heap = _Heap();
  owners.forEach((vertex, point) {
    distance[vertex] = 0;
    owner[vertex] = point;
    heap.add(0, vertex);
  });
  while (heap.isNotEmpty) {
    final (d, u) = heap.removeFirst();
    if (d > distance[u]) continue;
    for (final (v, w) in network.edgesOf(u)) {
      final next = d + w;
      if (next < distance[v]) {
        distance[v] = next;
        owner[v] = owner[u];
        heap.add(next, v);
      }
    }
  }

  // A road between two vertices of different owners joins the two points.
  for (var u = 0; u < network.count; u++) {
    if (owner[u] < 0) continue;
    for (final (v, w) in network.edgesOf(u)) {
      if (u < v && owner[v] >= 0 && owner[v] != owner[u]) {
        link(owner[u], owner[v], distance[u] + w + distance[v]);
      }
    }
  }

  final result = links.values.toList()
    ..sort((a, b) {
      final byFirst = (a[0] as String).compareTo(b[0] as String);
      return byFirst != 0
          ? byFirst
          : (a[1] as String).compareTo(b[1] as String);
    });
  return result;
}

/// The road network: vertices on a grid, and the edges between them.
class _Network {
  final _longitudes = <double>[];
  final _latitudes = <double>[];
  final _edges = <List<(int, double)>>[];
  final _byCell = <int, int>{};
  // For finding the nearest vertex: vertices by cells of 0.002 degrees.
  final _spatial = <int, List<int>>{};

  static const _spatialDegrees = 0.002;

  int get count => _longitudes.length;

  List<(int, double)> edgesOf(int vertex) => _edges[vertex];

  static int _cellKey(double lon, double lat, double size) {
    final x = (lon / size).round(), y = (lat / size).round();
    return x * 1000003 + y;
  }

  int _vertexAt(double lon, double lat) {
    final key = _cellKey(lon, lat, _cellDegrees);
    final known = _byCell[key];
    if (known != null) return known;
    final id = count;
    _byCell[key] = id;
    _longitudes.add(lon);
    _latitudes.add(lat);
    _edges.add([]);
    final cell = _cellKey(lon, lat, _spatialDegrees);
    _spatial.putIfAbsent(cell, () => []).add(id);
    return id;
  }

  /// Adds the road from [a] to [b] ([longitude, latitude]) in pieces.
  void addSegment(List<double> a, List<double> b) {
    final length = _meters(a[1], a[0], b[1], b[0]);
    final pieces = math.max(1, (length / _pieceMeters).ceil());
    var previous = _vertexAt(a[0], a[1]);
    for (var i = 1; i <= pieces; i++) {
      final t = i / pieces;
      final vertex = _vertexAt(
        a[0] + (b[0] - a[0]) * t,
        a[1] + (b[1] - a[1]) * t,
      );
      if (vertex != previous) {
        final w = length / pieces;
        _edges[previous].add((vertex, w));
        _edges[vertex].add((previous, w));
      }
      previous = vertex;
    }
  }

  /// The vertex nearest to the position, within [maxMeters]. Null if none.
  int? nearestVertex(double lon, double lat, double maxMeters) {
    final x = (lon / _spatialDegrees).round(),
        y = (lat / _spatialDegrees).round();
    int? best;
    var bestDistance = maxMeters;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (final v
            in _spatial[(x + dx) * 1000003 + (y + dy)] ?? const <int>[]) {
          final d = _meters(lat, lon, _latitudes[v], _longitudes[v]);
          if (d <= bestDistance) {
            bestDistance = d;
            best = v;
          }
        }
      }
    }
    return best;
  }
}

double _meters(double lat1, double lon1, double lat2, double lon2) {
  final dx = (lon2 - lon1) * 111320 * math.cos(lat1 * math.pi / 180);
  final dy = (lat2 - lat1) * 110574;
  return math.sqrt(dx * dx + dy * dy);
}

/// A binary heap of (distance, vertex), the smallest distance first.
class _Heap {
  final _distances = <double>[];
  final _vertices = <int>[];

  bool get isNotEmpty => _distances.isNotEmpty;

  void add(double distance, int vertex) {
    _distances.add(distance);
    _vertices.add(vertex);
    var i = _distances.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_distances[parent] <= _distances[i]) break;
      _swap(parent, i);
      i = parent;
    }
  }

  (double, int) removeFirst() {
    final first = (_distances.first, _vertices.first);
    final lastDistance = _distances.removeLast();
    final lastVertex = _vertices.removeLast();
    if (_distances.isNotEmpty) {
      _distances[0] = lastDistance;
      _vertices[0] = lastVertex;
      var i = 0;
      while (true) {
        final left = 2 * i + 1, right = left + 1;
        var smallest = i;
        if (left < _distances.length &&
            _distances[left] < _distances[smallest]) {
          smallest = left;
        }
        if (right < _distances.length &&
            _distances[right] < _distances[smallest]) {
          smallest = right;
        }
        if (smallest == i) break;
        _swap(smallest, i);
        i = smallest;
      }
    }
    return first;
  }

  void _swap(int a, int b) {
    final d = _distances[a];
    _distances[a] = _distances[b];
    _distances[b] = d;
    final v = _vertices[a];
    _vertices[a] = _vertices[b];
    _vertices[b] = v;
  }
}
