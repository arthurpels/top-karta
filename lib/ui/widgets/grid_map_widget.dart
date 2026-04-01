import 'package:flutter/material.dart';
import '../../../data/models/CampusMap.dart';

class GridMapWidget extends StatelessWidget {
  final CampusMap campusMap;

  const GridMapWidget({Key? key, required this.campusMap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(50.0),
      minScale: 0.1,
      maxScale: 10.0,
      constrained: false,
      child: CustomPaint(
        size: Size(
          (campusMap.cols * campusMap.cellSize).toDouble(),
          (campusMap.rows * campusMap.cellSize).toDouble(),
        ),
        painter: MapPainter(campusMap),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final CampusMap map;

  MapPainter(this.map);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke;
      
    for (int r = 0; r < map.rows; r++) {
      for (int c = 0; c < map.cols; c++) {
        final cell = map.grid[r][c];
        
        if (cell.weight <= 0) {
          paint.color = const Color(0xFF0051A0); 
        } else {
          paint.color = Colors.white; 
        }

        final rect = Rect.fromLTWH(
          c * map.cellSize.toDouble(),
          r * map.cellSize.toDouble(),
          map.cellSize.toDouble(),
          map.cellSize.toDouble(),
        );

        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
