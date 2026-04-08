import 'dart:isolate';
import 'dart:math';
import 'package:collection/collection.dart';

import '../core/genetic/chromosome.dart';
import '../data/models/CampusMap.dart';
import '../data/models/Place.dart';

class MealRouteProgress {
  final int generation;
  final RouteChromosome best;
  final bool isDone;

  const MealRouteProgress({
    required this.generation,
    required this.best,
    this.isDone = false,
  });
}

class MealRouteService {
  static const double _metersPerCell = 3.0;
  static const double _walkingSpeedMetersPerMinute = 5000 / 60;
  final List<Place> allPlaces;
  final CampusMap map;

  const MealRouteService(this.allPlaces, this.map);

  List<String> getAllUniqueDishes() {
    final set = <String>{};
    for (final place in allPlaces) {
      set.addAll(place.menu);
    }
    return set.toList()..sort();
  }

  Set<String> getUnavailableDishesNow(Iterable<String> dishes) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    return _findUnavailableDishesToday(
      dishes.toSet(),
      allPlaces,
      nowMinutes,
    ).toSet();
  }

  Stream<MealRouteProgress> optimizeRouteInIsolate(
    List<String> selectedDishes, {
    int generations = 100,
    int populationSize = 80,
  }) async* {
    if (selectedDishes.isEmpty) {
      return;
    }

    final selectedSet = selectedDishes.toSet();
    final candidates = allPlaces
        .where((p) => p.menu.any(selectedSet.contains))
        .toList(growable: false);
    if (candidates.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final startMinutesOfDay = now.hour * 60 + now.minute;
    final unavailableDishes = _findUnavailableDishesToday(
      selectedSet,
      candidates,
      startMinutesOfDay,
    );
    if (unavailableDishes.isNotEmpty) {
      throw Exception(
        'Сегодня недоступны блюда: ${unavailableDishes.join(', ')}',
      );
    }

    final requiredPlaces = _pickRequiredPlaces(selectedSet, candidates);
    if (requiredPlaces.isEmpty) {
      return;
    }
    final snappedCoords = requiredPlaces
        .map((place) => _snapToWalkable(place.gridRow, place.gridCol))
        .toList(growable: false);

    if (requiredPlaces.length == 1) {
      yield MealRouteProgress(
        generation: generations,
        best: RouteChromosome(requiredPlaces, precomputedFitness: 0),
        isDone: true,
      );
      return;
    }

    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _mealRouteIsolateEntry,
      <String, dynamic>{
        'sendPort': receivePort.sendPort,
        'places': requiredPlaces
            .asMap()
            .entries
            .map(
              (entry) => <String, dynamic>{
                'id': entry.value.id,
                'name': entry.value.name,
                'type': entry.value.type,
                'grid_row': snappedCoords[entry.key].$1,
                'grid_col': snappedCoords[entry.key].$2,
                'open_time': entry.value.openTime,
                'close_time': entry.value.closeTime,
                'price_level': entry.value.priceLevel,
                'menu': entry.value.menu,
              },
            )
            .toList(growable: false),
        'grid': map.grid
            .map(
              (row) => row.map((cell) => cell.weight).toList(growable: false),
            )
            .toList(growable: false),
        'rows': map.rows,
        'cols': map.cols,
        'generations': generations,
        'populationSize': populationSize,
        'startMinutesOfDay': startMinutesOfDay,
        'metersPerCell': _metersPerCell,
        'walkingSpeedMetersPerMinute': _walkingSpeedMetersPerMinute,
      },
    );

    try {
      await for (final dynamic event in receivePort) {
        if (event is! Map) {
          continue;
        }

        final type = event['type'] as String?;
        if (type == 'error') {
          throw Exception(event['message'] ?? 'Ошибка оптимизации маршрута');
        }

        final order = (event['order'] as List).cast<int>();
        final bestSequence = order.map((idx) => requiredPlaces[idx]).toList();
        final path = ((event['path'] as List?) ?? const [])
            .map((p) => (p[0] as int, p[1] as int))
            .toList();
        final distance = (event['distance'] as num).toDouble();
        final generation = event['generation'] as int;
        final isDone = type == 'done';

        yield MealRouteProgress(
          generation: generation,
          best: RouteChromosome(
            bestSequence,
            astarPath: path,
            precomputedFitness: distance,
          ),
          isDone: isDone,
        );

        if (isDone) {
          break;
        }
      }
    } finally {
      receivePort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  List<Place> _pickRequiredPlaces(
    Set<String> selectedDishes,
    List<Place> candidates,
  ) {
    final uncovered = Set<String>.from(selectedDishes);
    final chosen = <Place>[];
    final remaining = [...candidates];

    while (uncovered.isNotEmpty && remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final coverA = a.menu.where(uncovered.contains).length;
        final coverB = b.menu.where(uncovered.contains).length;
        return coverB.compareTo(coverA);
      });
      final pick = remaining.removeAt(0);
      final covered = pick.menu.where(uncovered.contains).toList();
      if (covered.isEmpty) {
        continue;
      }
      chosen.add(pick);
      uncovered.removeAll(covered);
    }

    if (uncovered.isNotEmpty) {
      return [];
    }
    return chosen;
  }

  List<String> _findUnavailableDishesToday(
    Set<String> selectedDishes,
    List<Place> candidates,
    int nowMinutes,
  ) {
    final unavailable = <String>[];
    for (final dish in selectedDishes) {
      final canServeToday = candidates.any((place) {
        if (!place.menu.contains(dish)) {
          return false;
        }
        final open = _parseTimeToMinutes(place.openTime);
        final close = _parseTimeToMinutes(place.closeTime);
        final remainingNow = _minutesUntilClose(
          nowMinutes.toDouble(),
          open,
          close,
        );
        if (remainingNow >= 0) {
          return true;
        }
        final wait = _waitUntilOpen(nowMinutes.toDouble(), open, close);
        return wait >= 0;
      });
      if (!canServeToday) {
        unavailable.add(dish);
      }
    }
    return unavailable;
  }

  (int, int) _snapToWalkable(int row, int col) {
    if (map.isInBounds(row, col) && map.getCell(row, col).weight < 1000) {
      return (row, col);
    }

    final maxRadius = max(map.rows, map.cols);
    for (int radius = 1; radius <= maxRadius; radius++) {
      (int, int)? best;
      var bestWeight = 1 << 30;
      for (int dr = -radius; dr <= radius; dr++) {
        for (int dc = -radius; dc <= radius; dc++) {
          if (dr.abs() != radius && dc.abs() != radius) {
            continue;
          }
          final nr = row + dr;
          final nc = col + dc;
          if (!map.isInBounds(nr, nc)) {
            continue;
          }
          final weight = map.getCell(nr, nc).weight;
          if (weight >= 1000) {
            continue;
          }
          if (best == null || weight < bestWeight) {
            best = (nr, nc);
            bestWeight = weight;
          }
        }
      }
      if (best != null) {
        return best;
      }
    }

    return (row, col);
  }
}

void _mealRouteIsolateEntry(Map<String, dynamic> message) {
  final sendPort = message['sendPort'] as SendPort;
  try {
    final rows = message['rows'] as int;
    final cols = message['cols'] as int;
    final generations = message['generations'] as int;
    final populationSize = message['populationSize'] as int;
    final startMinutesOfDay = message['startMinutesOfDay'] as int;
    final metersPerCell = (message['metersPerCell'] as num).toDouble();
    final walkingSpeedMetersPerMinute =
        (message['walkingSpeedMetersPerMinute'] as num).toDouble();

    final placesData = (message['places'] as List).cast<Map>();
    final places = placesData
        .map(
          (p) => _IsolatePlace(
            row: p['grid_row'] as int,
            col: p['grid_col'] as int,
            openMinutes: _parseTimeToMinutes(p['open_time'] as String),
            closeMinutes: _parseTimeToMinutes(p['close_time'] as String),
          ),
        )
        .toList(growable: false);

    final grid = (message['grid'] as List)
        .map((row) => (row as List).cast<int>())
        .toList(growable: false);

    final matrix = _buildTravelMinutesMatrix(
      places,
      grid,
      rows,
      cols,
      metersPerCell: metersPerCell,
      walkingSpeedMetersPerMinute: walkingSpeedMetersPerMinute,
    );
    final best = _runGenetic(
      matrix: matrix,
      places: places,
      startMinutesOfDay: startMinutesOfDay,
      generations: generations,
      populationSize: populationSize,
      onProgress: (generation, state) {
        sendPort.send(<String, dynamic>{
          'type': 'progress',
          'generation': generation,
          'distance': state.distance,
          'order': state.order,
        });
      },
    );

    final fullPath = _buildFullPath(best.order, places, grid, rows, cols);

    sendPort.send(<String, dynamic>{
      'type': 'done',
      'generation': generations,
      'distance': best.distance,
      'order': best.order,
      'path': fullPath.map((p) => [p.$1, p.$2]).toList(growable: false),
    });
  } catch (e) {
    sendPort.send(<String, dynamic>{'type': 'error', 'message': e.toString()});
  }
}

class _IsolatePlace {
  final int row;
  final int col;
  final int openMinutes;
  final int closeMinutes;

  const _IsolatePlace({
    required this.row,
    required this.col,
    required this.openMinutes,
    required this.closeMinutes,
  });
}

class _GaState {
  final List<int> order;
  final double distance;

  const _GaState(this.order, this.distance);
}

int _parseTimeToMinutes(String value) {
  final parts = value.split(':');
  if (parts.length != 2) {
    return 0;
  }
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
}

double _minutesUntilClose(double nowMinute, int openMinutes, int closeMinutes) {
  final minute = (nowMinute % 1440 + 1440) % 1440;
  if (openMinutes == closeMinutes) {
    return 0;
  }
  if (openMinutes < closeMinutes) {
    if (minute < openMinutes || minute >= closeMinutes) {
      return -1;
    }
    return closeMinutes - minute;
  }
  if (minute >= openMinutes || minute < closeMinutes) {
    if (minute >= openMinutes) {
      return (1440 - minute) + closeMinutes;
    }
    return closeMinutes - minute;
  }
  return -1;
}

double _waitUntilOpen(double nowMinute, int openMinutes, int closeMinutes) {
  final remaining = _minutesUntilClose(nowMinute, openMinutes, closeMinutes);
  if (remaining >= 0) {
    return 0;
  }
  final minute = (nowMinute % 1440 + 1440) % 1440;
  if (openMinutes < closeMinutes) {
    if (minute < openMinutes) {
      return openMinutes - minute;
    }
    return -1;
  }
  if (minute < openMinutes && minute >= closeMinutes) {
    return openMinutes - minute;
  }
  return -1;
}

List<List<double>> _buildTravelMinutesMatrix(
  List<_IsolatePlace> places,
  List<List<int>> grid,
  int rows,
  int cols, {
  required double metersPerCell,
  required double walkingSpeedMetersPerMinute,
}) {
  final n = places.length;
  final matrix = List.generate(
    n,
    (_) => List<double>.filled(n, 0),
    growable: false,
  );

  for (int i = 0; i < n; i++) {
    for (int j = i + 1; j < n; j++) {
      final route = _findPath(
        places[i].row,
        places[i].col,
        places[j].row,
        places[j].col,
        grid,
        rows,
        cols,
      );
      if (route == null || route.path.length < 2) {
        matrix[i][j] = 1e12;
        matrix[j][i] = 1e12;
        continue;
      }
      final steps = route.path.length - 1;
      final distanceMeters = steps * metersPerCell;
      final travelMinutes = distanceMeters / walkingSpeedMetersPerMinute;
      matrix[i][j] = travelMinutes;
      matrix[j][i] = travelMinutes;
    }
  }
  return matrix;
}

_GaState _runGenetic({
  required List<List<double>> matrix,
  required List<_IsolatePlace> places,
  required int startMinutesOfDay,
  required int generations,
  required int populationSize,
  required void Function(int generation, _GaState best) onProgress,
}) {
  final random = Random();
  final int n = matrix.length;
  final tournamentSize = min(5, populationSize);

  List<List<int>> population = List.generate(populationSize, (_) {
    final order = List<int>.generate(n, (index) => index);
    order.shuffle(random);
    return order;
  });

  double fitness(List<int> order) {
    const serviceMinutes = 5.0;
    const closingGraceMinutes = 30.0;
    const closedPenalty = 480.0;
    const lowSlackPenaltyFactor = 8.0;
    const urgencyOrderPenaltyFactor = 40.0;

    var total = 0.0;
    var currentMinute = startMinutesOfDay.toDouble();

    for (int i = 0; i < order.length; i++) {
      final placeIndex = order[i];
      final place = places[placeIndex];

      if (i > 0) {
        final travel = matrix[order[i - 1]][placeIndex];
        total += travel;
        currentMinute += travel;
      }

      final waitMinutes = _waitUntilOpen(
        currentMinute,
        place.openMinutes,
        place.closeMinutes,
      );
      if (waitMinutes < 0) {
        total += closedPenalty;
        continue;
      }
      total += waitMinutes;
      currentMinute += waitMinutes;

      final remainingAtArrival = _minutesUntilClose(
        currentMinute,
        place.openMinutes,
        place.closeMinutes,
      );
      if (remainingAtArrival <= 0) {
        total += closedPenalty;
      } else if (remainingAtArrival < closingGraceMinutes) {
        total +=
            (closingGraceMinutes - remainingAtArrival) * lowSlackPenaltyFactor;
      }

      final remainingAtStart = _minutesUntilClose(
        startMinutesOfDay.toDouble(),
        place.openMinutes,
        place.closeMinutes,
      );
      final urgencyWeight = 1 / (remainingAtStart + 30);
      total += i * urgencyWeight * urgencyOrderPenaltyFactor;

      total += serviceMinutes;
      currentMinute += serviceMinutes;
    }

    return total;
  }

  _GaState getBest(List<List<int>> p) {
    var bestOrder = p.first;
    var bestFit = fitness(bestOrder);
    for (final candidate in p.skip(1)) {
      final currentFit = fitness(candidate);
      if (currentFit < bestFit) {
        bestFit = currentFit;
        bestOrder = candidate;
      }
    }
    return _GaState(List<int>.from(bestOrder), bestFit);
  }

  List<int> tournamentPick() {
    List<int>? best;
    double bestFit = double.infinity;
    for (int i = 0; i < tournamentSize; i++) {
      final candidate = population[random.nextInt(population.length)];
      final fit = fitness(candidate);
      if (fit < bestFit) {
        bestFit = fit;
        best = candidate;
      }
    }
    return List<int>.from(best!);
  }

  List<int> orderCrossover(List<int> p1, List<int> p2) {
    final len = p1.length;
    final start = random.nextInt(len);
    final end = start + random.nextInt(len - start);
    final child = List<int?>.filled(len, null);

    for (int i = start; i <= end; i++) {
      child[i] = p1[i];
    }

    int childIndex = (end + 1) % len;
    int p2Index = (end + 1) % len;
    while (child.contains(null)) {
      final value = p2[p2Index];
      if (!child.contains(value)) {
        child[childIndex] = value;
        childIndex = (childIndex + 1) % len;
      }
      p2Index = (p2Index + 1) % len;
    }
    return child.cast<int>();
  }

  void mutateSwap(List<int> order) {
    final i = random.nextInt(order.length);
    final j = random.nextInt(order.length);
    final tmp = order[i];
    order[i] = order[j];
    order[j] = tmp;
  }

  for (int generation = 1; generation <= generations; generation++) {
    final best = getBest(population);
    if (generation == 1 || generation % 5 == 0 || generation == generations) {
      onProgress(generation, best);
    }

    final nextPopulation = <List<int>>[best.order];
    while (nextPopulation.length < populationSize) {
      final parent1 = tournamentPick();
      final parent2 = tournamentPick();
      final child = random.nextDouble() < 0.8
          ? orderCrossover(parent1, parent2)
          : parent1;
      if (random.nextDouble() < 0.15) {
        mutateSwap(child);
      }
      nextPopulation.add(child);
    }
    population = nextPopulation;
  }

  return getBest(population);
}

List<(int, int)> _buildFullPath(
  List<int> order,
  List<_IsolatePlace> places,
  List<List<int>> grid,
  int rows,
  int cols,
) {
  final fullPath = <(int, int)>[];
  for (int i = 0; i < order.length - 1; i++) {
    final from = places[order[i]];
    final to = places[order[i + 1]];
    final leg = _findPath(from.row, from.col, to.row, to.col, grid, rows, cols);
    if (leg == null || leg.path.isEmpty) {
      continue;
    }
    if (fullPath.isEmpty) {
      fullPath.addAll(leg.path);
    } else {
      fullPath.addAll(leg.path.skip(1));
    }
  }
  return fullPath;
}

class _PathResult {
  final List<(int, int)> path;
  final int cost;

  const _PathResult(this.path, this.cost);
}

_PathResult? _findPath(
  int startRow,
  int startCol,
  int endRow,
  int endCol,
  List<List<int>> grid,
  int rows,
  int cols,
) {
  bool inBounds(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;
  if (!inBounds(startRow, startCol) || !inBounds(endRow, endCol)) {
    return null;
  }
  if (grid[startRow][startCol] >= 1000 || grid[endRow][endCol] >= 1000) {
    return null;
  }

  final openQueue = HeapPriorityQueue<_Node>((a, b) => a.f.compareTo(b.f));
  final openBestG = <int, int>{};
  final closed = <int>{};

  int hash(int r, int c) => r * 1000 + c;
  int heuristic(int r, int c) => (endRow - r).abs() + (endCol - c).abs();

  final start = _Node(
    row: startRow,
    col: startCol,
    g: 0,
    h: heuristic(startRow, startCol),
    parent: null,
  );
  openQueue.add(start);
  openBestG[hash(startRow, startCol)] = 0;

  const deltas = [
    (-1, 0),
    (1, 0),
    (0, -1),
    (0, 1),
    (-1, -1),
    (-1, 1),
    (1, -1),
    (1, 1),
  ];

  while (openQueue.isNotEmpty) {
    final current = openQueue.removeFirst();
    final currentHash = hash(current.row, current.col);
    if (closed.contains(currentHash)) {
      continue;
    }
    closed.add(currentHash);

    if (current.row == endRow && current.col == endCol) {
      final path = <(int, int)>[];
      _Node? cursor = current;
      while (cursor != null) {
        path.add((cursor.row, cursor.col));
        cursor = cursor.parent;
      }
      final finalPath = path.reversed.toList(growable: false);
      return _PathResult(finalPath, current.g);
    }

    for (final (dr, dc) in deltas) {
      final nr = current.row + dr;
      final nc = current.col + dc;
      if (!inBounds(nr, nc)) {
        continue;
      }
      if (grid[nr][nc] >= 1000) {
        continue;
      }
      final stepIsDiagonal = dr != 0 && dc != 0;
      final stepCost = (stepIsDiagonal ? 14 : 10) + (grid[nr][nc] * 10);
      final tentativeG = current.g + stepCost;
      final neighborHash = hash(nr, nc);
      final bestKnown = openBestG[neighborHash];
      if (bestKnown != null && tentativeG >= bestKnown) {
        continue;
      }

      openBestG[neighborHash] = tentativeG;
      openQueue.add(
        _Node(
          row: nr,
          col: nc,
          g: tentativeG,
          h: heuristic(nr, nc),
          parent: current,
        ),
      );
    }
  }
  return null;
}

class _Node {
  final int row;
  final int col;
  final int g;
  final int h;
  final _Node? parent;

  const _Node({
    required this.row,
    required this.col,
    required this.g,
    required this.h,
    required this.parent,
  });

  int get f => g + h;
}
