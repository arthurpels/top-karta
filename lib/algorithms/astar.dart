import '../data/models/CampusMap.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

int cellHash(int row, int col) {
  return row * 1000 + col;
}

class PathNode {
  final int row;
  final int col;
  final int gCost;
  final int hCost;
  final PathNode? parent;

  PathNode({
    required this.row,
    required this.col,
    required this.gCost,
    required this.hCost,
    this.parent,
  });

  int get fCost => gCost + hCost;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathNode && other.row == row && other.col == col;

  @override
  int get hashCode => cellHash(row, col);
}

typedef AStarStepCallback =
    void Function(Set<int> openSet, Set<int> closedSet, (int, int)? current);

class AStarPathFinder {
  final CampusMap config;
  int lastIterations = 0;

  AStarPathFinder({required this.config});

  Future<List<(int, int)>?> findPath(
    int stRow,
    int stCol,
    int endRow,
    int endCol, {
    Set<int>? customObstacles,
    AStarStepCallback? onStep,
    Duration delay = const Duration(milliseconds: 5),
  }) async {
    if (!config.isInBounds(stRow, stCol) ||
        !config.isInBounds(endRow, endCol)) {
      debugPrint('Старт или финиш вне карты');
      return null;
    }

    final openQueue = PriorityQueue<PathNode>(
      (a, b) => a.fCost.compareTo(b.fCost),
    );
    final openSetHashes = <int>{};
    final closedSet = <int>{};

    final startNode = PathNode(
      row: stRow,
      col: stCol,
      gCost: 0,
      hCost: _heuristic(stRow, stCol, endRow, endCol),
    );

    openQueue.add(startNode);
    openSetHashes.add(startNode.hashCode);
    lastIterations = 0;

    while (openQueue.isNotEmpty) {
      lastIterations++;
      final current = openQueue.removeFirst();
      openSetHashes.remove(current.hashCode);

      if (onStep != null) {
        onStep(Set.from(openSetHashes), Set.from(closedSet), (
          current.row,
          current.col,
        ));
        await Future.delayed(delay);
      }

      if (current.row == endRow && current.col == endCol) {
        debugPrint('Путь найден за $lastIterations итераций!');
        return _reconstructPath(current);
      }

      if (closedSet.contains(current.hashCode)) continue;
      closedSet.add(current.hashCode);

      for (var (neighborRow, neighborCol) in _getNeighbors(current)) {
        if (!config.isInBounds(neighborRow, neighborCol)) continue;

        final neighborHash = getHashOf(neighborRow, neighborCol);

        if (closedSet.contains(neighborHash)) continue;

        bool isBlocked =
            (customObstacles != null &&
                customObstacles.contains(neighborHash)) ||
            config.getCell(neighborRow, neighborCol).weight >= 1000;

        if (isBlocked) continue;

        final weight = _getWeightOfTransition(
          current.row,
          current.col,
          neighborRow,
          neighborCol,
        );
        final tentativeGCost = current.gCost + weight;

        final neighborNode = PathNode(
          row: neighborRow,
          col: neighborCol,
          gCost: tentativeGCost,
          hCost: _heuristic(neighborRow, neighborCol, endRow, endCol),
          parent: current,
        );

        openQueue.add(neighborNode);
        openSetHashes.add(neighborHash);
      }
    }

    debugPrint('Путь не найден! Пройдено итераций: $lastIterations');
    return null;
  }

  List<(int, int)> _reconstructPath(PathNode last) {
    final path = <(int, int)>[];
    PathNode? current = last;

    while (current != null) {
      path.add((current.row, current.col));
      current = current.parent;
    }

    return path.reversed.toList();
  }

  int _heuristic(int r, int c, int endR, int endC) {
    return (endR - r).abs() + (endC - c).abs();
  }

  List<(int, int)> _getNeighbors(PathNode node) => [
    (node.row - 1, node.col),
    (node.row + 1, node.col),
    (node.row, node.col - 1),
    (node.row, node.col + 1),
    (node.row - 1, node.col - 1),
    (node.row - 1, node.col + 1),
    (node.row + 1, node.col - 1),
    (node.row + 1, node.col + 1),
  ];

  int _getWeightOfTransition(int fromRow, int fromCol, int toRow, int toCol) {
    final isDiagonal = (toRow - fromRow).abs() + (toCol - fromCol).abs() > 1;
    final int weight = config.getCell(toRow, toCol).weight;
    if (isDiagonal) {
      return 14 + (weight * 10);
    }
    return 10 + (weight * 10);
  }

  int getHashOf(int row, int col) {
    return row * 1000 + col;
  }
}
