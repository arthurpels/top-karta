import 'dart:math';

import '../algorithms/astar.dart';
import '../data/models/CampusMap.dart';
import '../data/models/Landmark.dart';

class TourProgress {
  final int iteration;
  final int maxIterations;
  final double bestCost;

  const TourProgress({
    required this.iteration,
    required this.maxIterations,
    required this.bestCost,
  });
}

class TourResult {
  final List<Landmark> orderedLandmarks;
  final List<(int, int)> mapPath;
  final double costUnits;

  const TourResult({
    required this.orderedLandmarks,
    required this.mapPath,
    required this.costUnits,
  });
}

class TourService {
  final Random _random = Random();

  Future<TourResult?> runAntColony({
    required CampusMap map,
    required (int, int) start,
    required List<Landmark> landmarks,
    int iterations = 80,
    int antCount = 30,
    double alpha = 1.0,
    double beta = 2.5,
    double evaporation = 0.45,
    double q = 150,
    void Function(TourProgress progress)? onProgress,
  }) async {
    if (landmarks.isEmpty) {
      return null;
    }

    final nodes = <(int, int)>[
      start,
      ...landmarks.map((l) => (l.gridRow, l.gridCol)),
    ];
    final n = nodes.length;
    final pairPath = <String, List<(int, int)>>{};
    final dist = List.generate(n, (_) => List<double>.filled(n, 0));
    final finder = AStarPathFinder(config: map);

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final from = _snapToWalkable(map, nodes[i].$1, nodes[i].$2);
        final to = _snapToWalkable(map, nodes[j].$1, nodes[j].$2);
        final path = await finder.findPath(from.$1, from.$2, to.$1, to.$2);
        final d = path == null || path.isEmpty
            ? _euclideanDistance(from, to) * 3.0
            : path.length.toDouble();
        dist[i][j] = d;
        dist[j][i] = d;
        if (path != null && path.isNotEmpty) {
          pairPath[_edgeKey(i, j)] = path;
          pairPath[_edgeKey(j, i)] = path.reversed.toList(growable: false);
        } else {
          pairPath[_edgeKey(i, j)] = [from, to];
          pairPath[_edgeKey(j, i)] = [to, from];
        }
      }
    }

    var pheromone = List.generate(n, (_) => List<double>.filled(n, 1.0));
    List<int>? bestRoute;
    var bestCost = double.infinity;

    for (int iteration = 1; iteration <= iterations; iteration++) {
      final antRoutes = <List<int>>[];
      final antCosts = <double>[];

      for (int ant = 0; ant < antCount; ant++) {
        final route = _buildAntRoute(dist, pheromone, alpha: alpha, beta: beta);
        final cost = _routeCost(route, dist);
        antRoutes.add(route);
        antCosts.add(cost);

        if (cost < bestCost) {
          bestCost = cost;
          bestRoute = route;
        }
      }

      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          pheromone[i][j] *= (1 - evaporation);
          if (pheromone[i][j] < 1e-6) {
            pheromone[i][j] = 1e-6;
          }
        }
      }

      for (int idx = 0; idx < antRoutes.length; idx++) {
        final route = antRoutes[idx];
        final cost = antCosts[idx];
        final delta = q / max(cost, 1.0);
        for (int i = 0; i < route.length - 1; i++) {
          final a = route[i];
          final b = route[i + 1];
          pheromone[a][b] += delta;
          pheromone[b][a] += delta;
        }
      }

      if (onProgress != null &&
          (iteration == 1 || iteration % 5 == 0 || iteration == iterations)) {
        onProgress(
          TourProgress(
            iteration: iteration,
            maxIterations: iterations,
            bestCost: bestCost,
          ),
        );
      }
    }

    if (bestRoute == null) {
      return null;
    }

    final orderedLandmarks = bestRoute
        .where((idx) => idx != 0)
        .map((idx) => landmarks[idx - 1])
        .toList(growable: false);

    final fullPath = <(int, int)>[];
    for (int i = 0; i < bestRoute.length - 1; i++) {
      final a = bestRoute[i];
      final b = bestRoute[i + 1];
      final edgePath = pairPath[_edgeKey(a, b)] ?? const <(int, int)>[];
      if (edgePath.isEmpty) {
        continue;
      }
      if (fullPath.isEmpty) {
        fullPath.addAll(edgePath);
      } else {
        fullPath.addAll(edgePath.skip(1));
      }
    }

    return TourResult(
      orderedLandmarks: orderedLandmarks,
      mapPath: fullPath,
      costUnits: bestCost,
    );
  }

  List<int> _buildAntRoute(
    List<List<double>> dist,
    List<List<double>> pheromone, {
    required double alpha,
    required double beta,
  }) {
    final n = dist.length;
    final route = <int>[0];
    final unvisited = <int>{for (int i = 1; i < n; i++) i};
    var current = 0;

    while (unvisited.isNotEmpty) {
      final choices = unvisited.toList(growable: false);
      final weights = <double>[];
      for (final next in choices) {
        final tau = pow(pheromone[current][next], alpha).toDouble();
        final eta = pow(1.0 / max(dist[current][next], 1e-6), beta).toDouble();
        weights.add(tau * eta);
      }
      final selectedIdx = _roulettePick(weights);
      final selected = choices[selectedIdx];
      route.add(selected);
      unvisited.remove(selected);
      current = selected;
    }

    return route;
  }

  int _roulettePick(List<double> weights) {
    final sum = weights.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) {
      return _random.nextInt(weights.length);
    }
    final roll = _random.nextDouble() * sum;
    var acc = 0.0;
    for (int i = 0; i < weights.length; i++) {
      acc += weights[i];
      if (roll <= acc) {
        return i;
      }
    }
    return weights.length - 1;
  }

  double _routeCost(List<int> route, List<List<double>> dist) {
    var sum = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      sum += dist[route[i]][route[i + 1]];
    }
    return sum;
  }

  String _edgeKey(int a, int b) => '$a-$b';

  (int, int) _snapToWalkable(CampusMap map, int row, int col) {
    if (map.isInBounds(row, col) && map.getCell(row, col).weight < 1000) {
      return (row, col);
    }
    final maxRadius = max(map.rows, map.cols);
    for (int radius = 1; radius <= maxRadius; radius++) {
      for (int dr = -radius; dr <= radius; dr++) {
        for (int dc = -radius; dc <= radius; dc++) {
          if (dr.abs() != radius && dc.abs() != radius) {
            continue;
          }
          final nr = row + dr;
          final nc = col + dc;
          if (!map.isInBounds(nr, nc)) {
            continue;
          }
          if (map.getCell(nr, nc).weight < 1000) {
            return (nr, nc);
          }
        }
      }
    }
    return (row, col);
  }

  double _euclideanDistance((int, int) a, (int, int) b) {
    final dx = (a.$2 - b.$2).toDouble();
    final dy = (a.$1 - b.$1).toDouble();
    return sqrt(dx * dx + dy * dy);
  }
}
