import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/CampusMap.dart';
import '../../data/models/Landmark.dart';
import '../../services/tour_service.dart';
import '../widgets/grid_map_widget.dart';

class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  CampusMap? _map;
  List<Landmark> _landmarks = [];
  final Set<String> _selectedIds = {};
  (int, int)? _startPoint;
  TourResult? _result;
  TourProgress? _progress;
  bool _isLoading = true;
  bool _isRunning = false;

  final TourService _tourService = TourService();
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final mapData = await CampusMap.load();
      final landmarksRaw = await rootBundle.loadString(
        AppStrings.landmarksAssetPath,
      );
      final list = (jsonDecode(landmarksRaw) as List)
          .map((e) => Landmark.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _map = mapData;
        _landmarks = list;
        _isLoading = false;
        final w = mapData.cellSize.toDouble();
        _transformationController.value = Matrix4.identity()
          ..translate(-((mapData.cols * w) / 4), -((mapData.rows * w) / 4))
          ..scale(1.5);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.loadingDataErrorPrefix}$e')),
      );
    }
  }

  Future<void> _runAco() async {
    if (_map == null ||
        _startPoint == null ||
        _selectedIds.isEmpty ||
        _isRunning) {
      return;
    }
    final selected = _landmarks
        .where((l) => _selectedIds.contains(l.id))
        .toList(growable: false);

    setState(() {
      _isRunning = true;
      _result = null;
      _progress = null;
    });

    final result = await _tourService.runAntColony(
      map: _map!,
      start: _startPoint!,
      landmarks: selected,
      onProgress: (p) {
        if (!mounted) {
          return;
        }
        setState(() {
          _progress = p;
        });
      },
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _isRunning = false;
      _result = result;
    });
  }

  void _onMapTap(TapDownDetails details) {
    if (_map == null || _isRunning) {
      return;
    }
    final matrix = _transformationController.value.clone()..invert();
    final local = MatrixUtils.transformPoint(matrix, details.localPosition);
    final w = _map!.cellSize.toDouble();
    final col = (local.dx / w).floor();
    final row = (local.dy / w).floor();
    if (!_map!.isInBounds(row, col)) {
      return;
    }
    setState(() {
      _startPoint = (row, col);
      _result = null;
    });
  }

  List<Widget> _buildMarkers() {
    if (_map == null) {
      return [];
    }
    final w = _map!.cellSize.toDouble();
    final markers = <Widget>[];

    for (final landmark in _landmarks) {
      final isSelected = _selectedIds.contains(landmark.id);
      final order = _result?.orderedLandmarks.indexWhere(
        (l) => l.id == landmark.id,
      );
      final hasOrder = order != null && order >= 0;
      final label = hasOrder ? '${order + 1}. ${landmark.name}' : landmark.name;
      markers.add(
        Positioned(
          left: landmark.gridCol * w - 16,
          top: landmark.gridRow * w - 36,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasOrder
                        ? Colors.deepPurple
                        : (isSelected ? Colors.teal : Colors.grey),
                    width: hasOrder ? 2 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.location_on,
                color: hasOrder
                    ? Colors.deepPurple
                    : (isSelected ? Colors.teal : Colors.grey),
                size: 30,
              ),
            ],
          ),
        ),
      );
    }

    if (_startPoint != null) {
      markers.add(
        Positioned(
          left: _startPoint!.$2 * w - 16,
          top: _startPoint!.$1 * w - 36,
          child: const Column(
            children: [
              Icon(Icons.flag, color: Colors.green, size: 30),
              Text(
                AppStrings.tourStartLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_map == null) {
      return const Center(child: Text(AppStrings.errorLoadMap));
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tourAppBarTitle)),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: _onMapTap,
            child: GridMapWidget(
              map: _map!,
              transformationController: _transformationController,
              markers: _buildMarkers(),
              customPainter: _result == null || _result!.mapPath.length < 2
                  ? null
                  : _TourPathPainter(
                      path: _result!.mapPath,
                      cellSize: _map!.cellSize.toDouble(),
                    ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              color: Colors.white.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.tourLandmarksTitle,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _landmarks.map((landmark) {
                        return FilterChip(
                          label: Text(landmark.name),
                          selected: _selectedIds.contains(landmark.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedIds.add(landmark.id);
                              } else {
                                _selectedIds.remove(landmark.id);
                              }
                              _result = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    if (_progress != null && _isRunning)
                      Text(
                        AppStrings.tourIterationProgress(
                          _progress!.iteration,
                          _progress!.maxIterations,
                          _progress!.bestCost,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    if (_result != null)
                      Text(
                        AppStrings.tourRouteFound(
                          _result!.orderedLandmarks.length,
                          _result!.costUnits,
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (_startPoint == null ||
                                    _selectedIds.isEmpty ||
                                    _isRunning)
                                ? null
                                : _runAco,
                            icon: _isRunning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.hiking),
                            label: Text(
                              _isRunning
                                  ? AppStrings.mealCalculating
                                  : AppStrings.tourBuild,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.tourTapStartHint,
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourPathPainter extends CustomPainter {
  final List<(int, int)> path;
  final double cellSize;

  const _TourPathPainter({required this.path, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) {
      return;
    }
    final paint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final poly = Path();
    final half = cellSize / 2;
    poly.moveTo(
      path.first.$2 * cellSize + half,
      path.first.$1 * cellSize + half,
    );
    for (int i = 1; i < path.length; i++) {
      poly.lineTo(path[i].$2 * cellSize + half, path[i].$1 * cellSize + half);
    }
    canvas.drawPath(poly, paint);
  }

  @override
  bool shouldRepaint(covariant _TourPathPainter oldDelegate) {
    return oldDelegate.path != path;
  }
}
