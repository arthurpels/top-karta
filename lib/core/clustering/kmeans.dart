import 'point.dart';
import 'dart:math';

class KMeans {
  final int k;
  final int maxIterations;

  KMeans({required this.k, this.maxIterations = 100});

  List<ClusterPoint> run(
    List<ClusterPoint> points, {
    List<List<double>>? distanceMatrix,
  }) {
    if (distanceMatrix != null) {
      return _runWithDistanceMatrix(points, distanceMatrix);
    }
    var centroids = _initCentroids(points, k);
    for (int i = 0; i < maxIterations; i++) {
      _assignClusters(points, centroids);
      final newCentroids = _recalculateCentroids(points, k);
      if (_centroidsEqual(centroids, newCentroids)) break;
      centroids = newCentroids;
    }

    _reorderClustersByX(points, centroids);

    return points;
  }

  List<ClusterPoint> _runWithDistanceMatrix(
    List<ClusterPoint> points,
    List<List<double>> distanceMatrix,
  ) {
    final random = Random(42);
    final medoids = points.map((p) => p.sourceIndex).toList()..shuffle(random);
    final medoidIndexes = medoids.take(k).toList(growable: true);

    for (int i = 0; i < maxIterations; i++) {
      _assignClustersWithMedoids(points, medoidIndexes, distanceMatrix);
      final newMedoids = _recalculateMedoids(
        points,
        medoidIndexes,
        distanceMatrix,
      );
      if (_listEquals(medoidIndexes, newMedoids)) {
        break;
      }
      for (int m = 0; m < newMedoids.length; m++) {
        medoidIndexes[m] = newMedoids[m];
      }
    }

    _reorderClustersByMedoidX(points, medoidIndexes);
    return points;
  }

  List<ClusterPoint> _initCentroids(List<ClusterPoint> points, int k) {
    final random = Random(42);
    final shuffled = List<ClusterPoint>.from(points)..shuffle(random);

    return shuffled
        .take(k)
        .map((p) => ClusterPoint(x: p.x, y: p.y, sourceIndex: p.sourceIndex))
        .toList();
  }

  double _distance(ClusterPoint a, ClusterPoint b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  void _assignClusters(
    List<ClusterPoint> points,
    List<ClusterPoint> centroids,
  ) {
    for (final point in points) {
      double minDist = double.infinity;
      int closestIndex = 0;

      for (int i = 0; i < centroids.length; i++) {
        final dist = _distance(point, centroids[i]);
        if (dist < minDist) {
          minDist = dist;
          closestIndex = i;
        }
      }
      point.clusterIndex = closestIndex;
    }
  }

  List<ClusterPoint> _recalculateCentroids(List<ClusterPoint> points, int k) {
    final centroids = <ClusterPoint>[];

    for (int i = 0; i < k; i++) {
      final clusterPoints = points.where((p) => p.clusterIndex == i).toList();

      if (clusterPoints.isEmpty) {
        centroids.add(
          ClusterPoint(
            x: points[i % points.length].x,
            y: points[i % points.length].y,
            sourceIndex: points[i % points.length].sourceIndex,
          ),
        );
      } else {
        double sumX = 0;
        double sumY = 0;
        for (final p in clusterPoints) {
          sumX += p.x;
          sumY += p.y;
        }
        centroids.add(
          ClusterPoint(
            x: sumX / clusterPoints.length,
            y: sumY / clusterPoints.length,
          ),
        );
      }
    }
    return centroids;
  }

  void _reorderClustersByX(
    List<ClusterPoint> points,
    List<ClusterPoint> centroids,
  ) {
    final indexed = List.generate(centroids.length, (i) => i);
    indexed.sort((a, b) => centroids[a].x.compareTo(centroids[b].x));

    final mapping = <int, int>{};
    for (int newIdx = 0; newIdx < indexed.length; newIdx++) {
      mapping[indexed[newIdx]] = newIdx;
    }

    for (final point in points) {
      point.clusterIndex = mapping[point.clusterIndex] ?? point.clusterIndex;
    }
  }

  bool _centroidsEqual(List<ClusterPoint> a, List<ClusterPoint> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i].x != b[i].x || a[i].y != b[i].y) return false;
    }
    return true;
  }

  void _assignClustersWithMedoids(
    List<ClusterPoint> points,
    List<int> medoidIndexes,
    List<List<double>> distanceMatrix,
  ) {
    for (final point in points) {
      var bestCluster = 0;
      var bestDistance = double.infinity;
      for (int cluster = 0; cluster < medoidIndexes.length; cluster++) {
        final d = distanceMatrix[point.sourceIndex][medoidIndexes[cluster]];
        if (d < bestDistance) {
          bestDistance = d;
          bestCluster = cluster;
        }
      }
      point.clusterIndex = bestCluster;
    }
  }

  List<int> _recalculateMedoids(
    List<ClusterPoint> points,
    List<int> currentMedoids,
    List<List<double>> distanceMatrix,
  ) {
    final next = <int>[];
    for (int cluster = 0; cluster < currentMedoids.length; cluster++) {
      final clusterPoints = points
          .where((p) => p.clusterIndex == cluster)
          .toList();
      if (clusterPoints.isEmpty) {
        next.add(currentMedoids[cluster]);
        continue;
      }
      int bestMedoid = clusterPoints.first.sourceIndex;
      double bestCost = double.infinity;
      for (final candidate in clusterPoints) {
        double total = 0;
        for (final other in clusterPoints) {
          total += distanceMatrix[candidate.sourceIndex][other.sourceIndex];
        }
        if (total < bestCost) {
          bestCost = total;
          bestMedoid = candidate.sourceIndex;
        }
      }
      next.add(bestMedoid);
    }
    return next;
  }

  void _reorderClustersByMedoidX(
    List<ClusterPoint> points,
    List<int> medoidIndexes,
  ) {
    final indexed = List.generate(medoidIndexes.length, (i) => i);
    final sourceByIndex = {for (final p in points) p.sourceIndex: p};
    indexed.sort((a, b) {
      final pa = sourceByIndex[medoidIndexes[a]];
      final pb = sourceByIndex[medoidIndexes[b]];
      final xa = pa?.x ?? 0;
      final xb = pb?.x ?? 0;
      return xa.compareTo(xb);
    });

    final mapping = <int, int>{};
    for (int newIdx = 0; newIdx < indexed.length; newIdx++) {
      mapping[indexed[newIdx]] = newIdx;
    }

    for (final point in points) {
      point.clusterIndex = mapping[point.clusterIndex] ?? point.clusterIndex;
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
