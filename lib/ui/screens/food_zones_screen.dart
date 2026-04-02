import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/CampusMap.dart';
import '../../data/models/Place.dart';
import '../../core/clustering/kmeans.dart';
import '../../core/clustering/point.dart';
import '../widgets/grid_map_widget.dart';

class FoodZonesScreen extends StatefulWidget {
  const FoodZonesScreen({super.key});

  @override
  State<FoodZonesScreen> createState() => _FoodZonesScreenState();
}

class _FoodZonesScreenState extends State<FoodZonesScreen> {
  CampusMap? _map;
  List<Place> _places = [];
  List<ClusterPoint> _points = [];
  bool _isLoading = true;

  final TransformationController _transformationController =
      TransformationController();

  static const List<Color> _clusterColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.deepPurpleAccent,
    Colors.orangeAccent,
    Colors.amberAccent,
  ];

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

      final kmeans = KMeans(k: 3, maxIterations: 50);
      final points = places.map((p) {
        return ClusterPoint(
          x: p.gridCol.toDouble(),
          y: p.gridRow.toDouble(),
        );
      }).toList();
      
      final clusteredPoints = kmeans.run(points);

      setState(() {
        _map = mapData;
        _places = places;
        _points = clusteredPoints;
        _isLoading = false;

        if (_map != null) {
          final w = _map!.cellSize.toDouble();
          _transformationController.value = Matrix4.identity()
            ..translate(-(_map!.cols * w / 4), -(_map!.rows * w / 4))
            ..scale(1.5);
        }
      });
    } catch (e) {
      debugPrint("Error loading data: \$e");
      setState(() => _isLoading = false);
    }
  }

  List<Widget> _buildMarkers() {
    if (_map == null) return [];
    
    final w = _map!.cellSize.toDouble();
    final List<Widget> markers = [];

    for (int i = 0; i < _places.length; i++) {
      final place = _places[i];
      final cluster = _points[i].clusterIndex;
      final color = cluster >= 0 && cluster < _clusterColors.length
          ? _clusterColors[cluster]
          : Colors.black;

      markers.add(
        Positioned(
          left: place.gridCol * w - 16,
          top: place.gridRow * w - 32,
          child: GestureDetector(
            onTap: () {
              _showPlaceInfo(place, cluster);
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(
                    place.name,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(
                  Icons.location_on,
                  color: color,
                  size: 32,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  void _showPlaceInfo(Place place, int clusterIndex) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant, color: clusterIndex >= 0 ? _clusterColors[clusterIndex % _clusterColors.length] : Colors.black),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      place.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text("Тип: \${place.type}"),
              Text("Время работы: \${place.openTime} - \${place.closeTime}"),
              Text("Цены: \${place.priceLevel}"),
              const SizedBox(height: 12),
              const Text("Меню:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: place.menu
                    .map((item) => Chip(
                          label: Text(item, style: const TextStyle(fontSize: 12)),
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_map == null) {
      return const Center(child: Text("Не удалось загрузить карту"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Зоны еды (K-Means)'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Карта
          GridMapWidget(
            map: _map!,
            transformationController: _transformationController,
            markers: _buildMarkers(),
          ),
          
          Positioned(
            left: 16,
            bottom: 16,
            child: Card(
              color: Colors.white.withValues(alpha: 0.9),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Зоны питания:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildLegendItem('Зона 1 (Запад)', 0),
                    _buildLegendItem('Зона 2 (Центр)', 1),
                    _buildLegendItem('Зона 3 (Восток)', 2),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Центровка
          if (_map != null) {
            final w = _map!.cellSize.toDouble();
            _transformationController.value = Matrix4.identity()
              ..translate(-(_map!.cols * w / 4), -(_map!.rows * w / 4))
              ..scale(1.5);
          }
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  Widget _buildLegendItem(String label, int clusterIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _clusterColors[clusterIndex % _clusterColors.length],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
