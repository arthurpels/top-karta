class GridCell {
  final int row;
  final int col;
  final int weight;

  const GridCell({required this.row, required this.col, required this.weight});

  bool get isWalkable => weight > 0 && weight < 1000;
}
