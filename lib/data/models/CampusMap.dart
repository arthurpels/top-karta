import 'dart:convert';
import 'package:flutter/services.dart';
import 'GridCell.dart';

class CampusMap{
  final int rows;
  final int cols;
  final int cellSize;
  final List<List<GridCell>> grid;

  CampusMap({
    required this.rows,
    required this.cols,
    required this.cellSize,
    required this.grid
  });

  static Future<CampusMap> load() async{
    final jsonString = await rootBundle.loadString('assets/map_grid.json');
    final data = jsonDecode(jsonString);
    final config = data['config'];
    final matrix = data['matrix'] as List;

    final grid = <List<GridCell>>[];
    for (int r = 0; r < matrix.length; r++){
      final row = <GridCell>[];
      for (int c = 0; c < matrix[r].length; c++){
        row.add(GridCell(row: r, col: c, weight: matrix[r][c] as int));
      }
      grid.add(row);
    }
  

  return CampusMap(
    rows: config['rows'],
    cols: config['cols'],
    cellSize: config['cellSize'],
    grid: grid,
  );
  }
  bool isInBounds(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }
  GridCell getCell(int row, int col) => grid[row][col];
}