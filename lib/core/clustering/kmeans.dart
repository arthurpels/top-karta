import 'point.dart';
import 'dart:math';

class KMeans {
  final int k;
  final int maxIterations;

  KMeans({required this.k, this.maxIterations = 100});

  List<ClusterPoint> run(List<ClusterPoint> points) {
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

  List<ClusterPoint> _initCentroids(List<ClusterPoint> points, int k) {
    final random = Random(42);
    final shuffled = List<ClusterPoint>.from(points)..shuffle(random);

    return shuffled.take(k).map((p) => ClusterPoint(x: p.x, y: p.y)).toList();
  }

  double _distance(ClusterPoint a, ClusterPoint b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  void _assignClusters(List<ClusterPoint> points, List<ClusterPoint> centroids){
    for(final point in points){
      double minDist = double.infinity;
      int closestIndex = 0;

      for (int i = 0; i < centroids.length; i++){
        final dist = _distance(point, centroids[i]);
        if (dist < minDist){
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
        centroids.add(ClusterPoint(x: points[i % points.length].x, y: points[i % points.length].y));
      } else {
        double sumX = 0;
        double sumY = 0;
        for (final p in clusterPoints) {
          sumX += p.x;
          sumY += p.y;
        }
        centroids.add(ClusterPoint(
          x: sumX / clusterPoints.length,
          y: sumY / clusterPoints.length,
        ));
      }
    }
    return centroids;
  }

  void _reorderClustersByX(List<ClusterPoint> points, List<ClusterPoint> centroids) {

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

}
