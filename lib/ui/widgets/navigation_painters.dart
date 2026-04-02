import 'package:flutter/material.dart';

class SearchPainter extends CustomPainter {
  final Set<int> openSet;
  final Set<int> closedSet;
  final (int, int)? current;
  final double cellSize;

  SearchPainter({
    required this.openSet,
    required this.closedSet,
    this.current,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final closedPaint = Paint()..color = Colors.blue.withValues(alpha: 0.3);
    final openPaint = Paint()..color = Colors.yellow.withValues(alpha: 0.5);
    final currentPaint = Paint()..color = Colors.orange.withValues(alpha: 0.8);

    for (final hash in closedSet) {
      final row = hash ~/ 1000;
      final col = hash % 1000;
      canvas.drawRect(
        Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
        closedPaint,
      );
    }

    for (final hash in openSet) {
      final row = hash ~/ 1000;
      final col = hash % 1000;
      canvas.drawRect(
        Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
        openPaint,
      );
    }

    if (current != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          current!.$2 * cellSize,
          current!.$1 * cellSize,
          cellSize,
          cellSize,
        ),
        currentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SearchPainter oldDelegate) {
    return oldDelegate.openSet != openSet ||
        oldDelegate.closedSet != closedSet ||
        oldDelegate.current != current;
  }
}

class ObstaclePainter extends CustomPainter {
  final Set<int> obstacles;
  final double cellSize;

  ObstaclePainter({
    required this.obstacles,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    for (final hash in obstacles) {
      final row = hash ~/ 1000;
      final col = hash % 1000;
      final rect = Rect.fromLTWH(
        col * cellSize,
        row * cellSize,
        cellSize,
        cellSize,
      );

      canvas.drawRect(rect, paint);
      
      if (cellSize > 4) {
        canvas.drawLine(rect.topLeft, rect.bottomRight, linePaint);
        canvas.drawLine(rect.topRight, rect.bottomLeft, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ObstaclePainter oldDelegate) {
    return oldDelegate.obstacles != obstacles;
  }
}
