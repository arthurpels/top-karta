import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/CampusMap.dart';
import '../../data/models/Place.dart';
import '../../services/meal_route_service.dart';
import '../../core/genetic/chromosome.dart';
import '../widgets/grid_map_widget.dart';
import '../widgets/navigation_painters.dart';
import '../widgets/genetic_progress.dart';

class MealRouteScreen extends StatefulWidget {
  const MealRouteScreen({super.key});

  @override
  State<MealRouteScreen> createState() => _MealRouteScreenState();
}

class _MealRouteScreenState extends State<MealRouteScreen> {
  CampusMap? _map;
  List<Place> _allPlaces = [];
  List<String> _allDishes = [];
  final Set<String> _selectedDishes = {};
  RouteChromosome? _bestRoute;
  MealRouteService? _routeService;
  bool _isLoading = true;
  bool _isOptimizing = false;
  
  int _currentGeneration = 0;
  double _currentBestDistance = 0;

  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final mapData = await CampusMap.load();
      final placesString = await rootBundle.loadString('assets/places.json');
      final List<dynamic> placesJson = jsonDecode(placesString);
      final places = placesJson.map((p) => Place.fromJson(p)).toList();

      setState(() {
        _map = mapData;
        _allPlaces = places;
        _routeService = MealRouteService(places);
        _allDishes = _routeService!.getAllUniqueDishes();
        _isLoading = false;

        if (_map != null) {
          final w = _map!.cellSize.toDouble();
          _transformationController.value = Matrix4.identity()
            ..translate(-(_map!.cols * w / 4), -(_map!.rows * w / 4))
            ..scale(1.5);
        }
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onOptimize() async {
    if (_selectedDishes.isEmpty || _routeService == null) return;

    setState(() {
      _isOptimizing = true;
      _currentGeneration = 0;
      _currentBestDistance = 0;
      _bestRoute = null;
    });

    final result = await Future(() {
      return _routeService!.findBestRoute(
        _selectedDishes.toList(),
        onProgress: (gen, best) {
          if (gen % 5 == 0 || gen == 100) {
            setState(() {
              _currentGeneration = gen;
              _currentBestDistance = best.fitness;
              _bestRoute = best;
            });
          }
        },
      );
    });

    setState(() {
      _bestRoute = result;
      _isOptimizing = false;
    });
  }

  List<Widget> _buildMarkers() {
    if (_map == null || _bestRoute == null) return [];
    
    final w = _map!.cellSize.toDouble();
    final List<Widget> markers = [];
    final sequence = _bestRoute!.sequence;

    for (int i = 0; i < sequence.length; i++) {
      final place = sequence[i];
      markers.add(
        Positioned(
          left: place.gridCol * w - 16,
          top: place.gridRow * w - 32,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Text(
                  "${i + 1}. ${place.name}",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(
                Icons.location_on,
                color: Colors.orange,
                size: 32,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Маршрут еды (GA)'),
        actions: [
          if (_bestRoute != null && !_isOptimizing)
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: _showRouteDetails,
            ),
        ],
      ),
      body: Stack(
        children: [
          _map != null
              ? GridMapWidget(
                  map: _map!,
                  transformationController: _transformationController,
                  markers: _buildMarkers(),
                  customPainter: _bestRoute != null 
                    ? PathPainter(
                        points: _bestRoute!.sequence.map((p) => Offset(p.gridCol.toDouble(), p.gridRow.toDouble())).toList(),
                        cellSize: _map!.cellSize.toDouble(),
                        color: Colors.orange,
                      )
                    : null,
                )
              : const Center(child: Text("Ошибка загрузки карты")),
          
          if (_bestRoute == null && !_isOptimizing)
            _buildDishSelector()
          else if (_isOptimizing)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: GeneticProgressWidget(
                generation: _currentGeneration,
                maxGenerations: 100,
                bestDistance: _currentBestDistance,
              ),
            )
          else
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.white.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Оптимальный маршрут найден!",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orange[800], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("Заведений: ${_bestRoute!.sequence.length} | Расстояние: ${_bestRoute!.fitness.toStringAsFixed(1)} ед."),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_bestRoute != null && !_isOptimizing)
            FloatingActionButton(
              heroTag: 'clear',
              onPressed: () => setState(() => _bestRoute = null),
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.close),
            ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'opt',
            onPressed: (_selectedDishes.isEmpty || _isOptimizing) ? null : _onOptimize,
            label: Text(_isOptimizing ? 'Считаем...' : 'Найти еду'),
            icon: _isOptimizing 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.bolt),
          ),
        ],
      ),
    );
  }

  Widget _buildDishSelector() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Что хотите купить?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _allDishes.map((dish) {
                    final isSelected = _selectedDishes.contains(dish);
                    return FilterChip(
                      label: Text(dish),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) _selectedDishes.add(dish);
                          else _selectedDishes.remove(dish);
                        });
                      },
                      selectedColor: Colors.orange.withValues(alpha: 0.3),
                      checkmarkColor: Colors.orange,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRouteDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Машрут покупки", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _bestRoute!.sequence.length,
                  itemBuilder: (context, index) {
                    final p = _bestRoute!.sequence[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.orange, child: Text("${index + 1}", style: const TextStyle(color: Colors.white))),
                      title: Text(p.name),
                      subtitle: Text("Меню: ${p.menu.where((d) => _selectedDishes.contains(d)).join(', ')}"),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class PathPainter extends CustomPainter {
  final List<Offset> points;
  final double cellSize;
  final Color color;

  PathPainter({required this.points, required this.cellSize, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points[0].dx * cellSize, points[0].dy * cellSize);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * cellSize, points[i].dy * cellSize);
    }

    canvas.drawPath(path, paint);
    
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = Offset(points[i].dx * cellSize, points[i].dy * cellSize);
      final p2 = Offset(points[i+1].dx * cellSize, points[i+1].dy * cellSize);
      
      final direction = (p2 - p1);
      final angle = direction.direction;
      final center = p1 + direction * 0.5;
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      
      final arrowPath = Path()
        ..moveTo(5, 0)
        ..lineTo(-5, -5)
        ..lineTo(-5, 5)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) => true;
}
