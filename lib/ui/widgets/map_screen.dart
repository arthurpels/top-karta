import 'package:flutter/material.dart';
import '../../data/models/CampusMap.dart';
import 'grid_map_widget.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Future<CampusMap>? _campusMapFuture;

  @override
  void initState() {
    super.initState();
    _campusMapFuture = CampusMap.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0051A0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 45),
              child: Text(
                'Итераций: 0',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<CampusMap>(
        future: _campusMapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          } else if (snapshot.hasData) {
            return Center(child: GridMapWidget(map: snapshot.data!));
          } else {
            return const Center(child: Text('Нет данных'));
          }
        },
      ),
    );
  }
}
