class ClusterPoint {
  final double x;
  final double y;
  final int sourceIndex;
  int clusterIndex;

  ClusterPoint({
    required this.x,
    required this.y,
    this.sourceIndex = -1,
    this.clusterIndex = -1,
  });
}
