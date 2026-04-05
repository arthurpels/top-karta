import 'package:flutter/material.dart';
import '../../data/models/CampusMap.dart';

class PixelCanvas extends CustomPainter {
  final CampusMap map;

  PixelCanvas({required this.map});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = map.cellSize.toDouble();

    for (int r = 0; r < map.rows; r++) {
      for (int c = 0; c < map.cols; c++) {
        int weight = map.grid[r][c].weight;

        switch (weight) {
          case 1:
            paint.color = const Color(0xFFF1F3F4);
            break;
          case 100:
            paint.color = const Color(0xFFC8E6C9);
            break;
          case 500:
            paint.color = const Color(0xFF81C784);
            break;
          case 1000:
            paint.color = const Color(0xFF388E3C);
            break;
          case 999999:
            paint.color = const Color(0xFF37474F);
            break;
          default:
            paint.color = Colors.blueGrey;
        }

        canvas.drawRect(
          Rect.fromLTWH(c * w, r * w, w, w),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelCanvas oldDelegate) {
    return oldDelegate.map != map;
  }
}
