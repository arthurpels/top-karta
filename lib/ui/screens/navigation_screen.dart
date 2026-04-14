import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/CampusMap.dart';
import '../../algorithms/astar.dart';
import '../widgets/navigation_painters.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  CampusMap? _map;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isEditMode = false;
  bool _animateSearch = true;

  (int, int)? _startPoint;
  (int, int)? _endPoint;

  final Set<int> _customObstacles = {};

  Set<int> _searchOpenSet = {};
  Set<int> _searchClosedSet = {};
  (int, int)? _searchCurrent;

  List<(int, int)>? _path;
  String? _statusMessage;
  int _iterations = 0;

  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  Future<void> _loadMap() async {
    try {
      final mapData = await CampusMap.load();
      setState(() {
        _map = mapData;
        _isLoading = false;

        final w = _map!.cellSize.toDouble();
        _transformationController.value = Matrix4.identity()
          ..translate(-(_map!.cols * w / 4), -(_map!.rows * w / 4))
          ..scale(1.5);
      });
    } catch (e) {
      debugPrint("Error loading map: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onMapTap(TapDownDetails details, BoxConstraints constraints) {
    if (_map == null || _isSearching) return;

    final matrix = _transformationController.value.clone()..invert();
    final localPoint = MatrixUtils.transformPoint(
      matrix,
      details.localPosition,
    );

    final w = _map!.cellSize.toDouble();
    final col = (localPoint.dx / w).floor();
    final row = (localPoint.dy / w).floor();

    if (!_map!.isInBounds(row, col)) return;

    final hash = row * 1000 + col;

    if (_isEditMode) {
      setState(() {
        if (_customObstacles.contains(hash)) {
          _customObstacles.remove(hash);
        } else {
          _customObstacles.add(hash);
        }
      });
      return;
    }

    setState(() {
      if (_startPoint == null) {
        _startPoint = (row, col);
        _endPoint = null;
        _path = null;
        _resetSearchState();
        _statusMessage = AppStrings.navSelectFinish;
        _iterations = 0;
      } else if (_endPoint == null) {
        _endPoint = (row, col);
        _findPath();
      } else {
        _startPoint = (row, col);
        _endPoint = null;
        _path = null;
        _resetSearchState();
        _statusMessage = AppStrings.navSelectFinish;
        _iterations = 0;
      }
    });
  }

  void _resetSearchState() {
    _searchOpenSet = {};
    _searchClosedSet = {};
    _searchCurrent = null;
  }

  Future<void> _findPath() async {
    if (_map == null || _startPoint == null || _endPoint == null) return;

    setState(() {
      _isSearching = true;
      _statusMessage = AppStrings.searchingRoute;
      _path = null;
      _resetSearchState();
    });

    final finder = AStarPathFinder(config: _map!);
    final path = await finder.findPath(
      _startPoint!.$1,
      _startPoint!.$2,
      _endPoint!.$1,
      _endPoint!.$2,
      customObstacles: _customObstacles,
      onStep: _animateSearch
          ? (open, closed, current) {
              setState(() {
                _searchOpenSet = open;
                _searchClosedSet = closed;
                _searchCurrent = current;
              });
            }
          : null,
    );

    setState(() {
      _isSearching = false;
      _iterations = finder.lastIterations;

      if (path != null && path.isNotEmpty) {
        _path = path;
        final distanceMeters = path.length * 3;
        final timeMinutes = (distanceMeters / 83.3).ceil();
        _statusMessage = AppStrings.navRouteFound(
          distanceMeters,
          timeMinutes,
          _iterations,
        );
      } else {
        _statusMessage = AppStrings.navRouteNotFound(_iterations);
      }
    });
  }

  void _resetPath() {
    setState(() {
      _startPoint = null;
      _endPoint = null;
      _path = null;
      _resetSearchState();
      _customObstacles.clear();
      _statusMessage = null;
      _iterations = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_map == null) {
      return const Scaffold(body: Center(child: Text(AppStrings.errorLoadMap)));
    }

    final w = _map!.cellSize.toDouble();
    final mapWidth = _map!.cols * w;
    final mapHeight = _map!.rows * w;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navAppBarTitle),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _animateSearch ? Icons.play_circle : Icons.play_disabled,
            ),
            tooltip: _animateSearch
                ? AppStrings.navAnimationOn
                : AppStrings.navAnimationOff,
            onPressed: () => setState(() => _animateSearch = !_animateSearch),
          ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.edit : Icons.edit_note),
            color: _isEditMode ? Colors.orange : null,
            tooltip: _isEditMode
                ? AppStrings.navEditMode
                : AppStrings.navNormalMode,
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
          ),
          if (_startPoint != null || _customObstacles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: AppStrings.navResetAll,
              onPressed: _resetPath,
            ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) => _onMapTap(details, constraints),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.2,
                  maxScale: 8.0,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(2000),
                  child: SizedBox(
                    width: mapWidth,
                    height: mapHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            AppStrings.mapAssetPath,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high,
                          ),
                        ),

                        if (_searchOpenSet.isNotEmpty ||
                            _searchClosedSet.isNotEmpty)
                          CustomPaint(
                            size: Size(mapWidth, mapHeight),
                            painter: SearchPainter(
                              openSet: _searchOpenSet,
                              closedSet: _searchClosedSet,
                              current: _searchCurrent,
                              cellSize: w,
                            ),
                          ),

                        if (_customObstacles.isNotEmpty)
                          CustomPaint(
                            size: Size(mapWidth, mapHeight),
                            painter: ObstaclePainter(
                              obstacles: _customObstacles,
                              cellSize: w,
                            ),
                          ),

                        if (_path != null)
                          CustomPaint(
                            size: Size(mapWidth, mapHeight),
                            painter: _PathPainter(path: _path!, cellSize: w),
                          ),

                        if (_startPoint != null)
                          Positioned(
                            left: _startPoint!.$2 * w - 16,
                            top: _startPoint!.$1 * w - 40,
                            child: const _MapPin(
                              color: Colors.green,
                              icon: Icons.flag,
                              label: AppStrings.navStartLabel,
                            ),
                          ),

                        if (_endPoint != null)
                          Positioned(
                            left: _endPoint!.$2 * w - 16,
                            top: _endPoint!.$1 * w - 40,
                            child: const _MapPin(
                              color: Colors.red,
                              icon: Icons.location_on,
                              label: AppStrings.navFinishLabel,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 4,
              color: Colors.white.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearching)
                      const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(AppStrings.searchingRoute),
                        ],
                      )
                    else if (_statusMessage != null)
                      Row(
                        children: [
                          Icon(
                            _path != null
                                ? Icons.check_circle
                                : (_endPoint != null
                                      ? Icons.error_outline
                                      : Icons.touch_app),
                            color: _path != null
                                ? Colors.green
                                : (_endPoint != null
                                      ? Colors.red
                                      : const Color(0xFF005AAB)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.touch_app, color: Color(0xFF005AAB)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.navTapForStart,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
}

class _PathPainter extends CustomPainter {
  final List<(int, int)> path;
  final double cellSize;

  _PathPainter({required this.path, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pathPaint = Paint()
      ..color = const Color(0xFF005AAB)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final shadowPath = Path();
    final mainPath = Path();

    final halfCell = cellSize / 2;

    shadowPath.moveTo(
      path[0].$2 * cellSize + halfCell + 1,
      path[0].$1 * cellSize + halfCell + 1,
    );
    mainPath.moveTo(
      path[0].$2 * cellSize + halfCell,
      path[0].$1 * cellSize + halfCell,
    );

    for (int i = 1; i < path.length; i++) {
      shadowPath.lineTo(
        path[i].$2 * cellSize + halfCell + 1,
        path[i].$1 * cellSize + halfCell + 1,
      );
      mainPath.lineTo(
        path[i].$2 * cellSize + halfCell,
        path[i].$1 * cellSize + halfCell,
      );
    }

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(mainPath, pathPaint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.path != path;
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _MapPin({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Icon(
          icon,
          color: color,
          size: 36,
          shadows: const [
            Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(1, 1)),
          ],
        ),
      ],
    );
  }
}
