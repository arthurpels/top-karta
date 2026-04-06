import 'package:flutter/material.dart';
import '../../data/models/CampusMap.dart';
import 'pixel_canvas.dart';

class GridMapWidget extends StatelessWidget {
  final CustomPainter? customPainter;
  final CampusMap map;
  final List<Widget> markers;
  final TransformationController? transformationController;
  final bool useRealMap;

  const GridMapWidget({
    super.key,
    required this.map,
    this.markers = const [],
    this.transformationController,
    this.useRealMap = true,
    this.customPainter,
  });

  @override
  Widget build(BuildContext context) {
    final w = map.cellSize.toDouble();
    final width = map.cols * w;
    final height = map.rows * w;

    return InteractiveViewer(
      transformationController: transformationController,
      minScale: 0.2,
      maxScale: 5.0,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(500),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            if (useRealMap)
              Positioned.fill(
                child: Image.asset(
                  'assets/map.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              )
            else
              CustomPaint(
                size: Size(width, height),
                painter: PixelCanvas(map: map),
              ),

            if (customPainter != null)
              Positioned.fill(child: CustomPaint(painter: customPainter)),

            ...markers,
          ],
        ),
      ),
    );
  }
}
