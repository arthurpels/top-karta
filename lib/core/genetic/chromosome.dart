import '../../data/models/Place.dart';
import 'dart:math';

class RouteChromosome {
  final List<Place> sequence;
  final List<(int, int)> astarPath;
  final double? _precomputedFitness;
  double? _fitness;

  RouteChromosome(
    this.sequence, {
    this.astarPath = const [],
    double? precomputedFitness,
  }) : _precomputedFitness = precomputedFitness;

  double get fitness {
    _fitness ??= _precomputedFitness ?? _calculateFitness();
    return _fitness!;
  }

  double _calculateFitness() {
    if (sequence.isEmpty) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < sequence.length - 1; i++) {
      totalDistance += _distance(sequence[i], sequence[i + 1]);
    }

    return totalDistance;
  }

  double _distance(Place a, Place b) {
    return sqrt(pow(a.gridCol - b.gridCol, 2) + pow(a.gridRow - b.gridRow, 2));
  }

  RouteChromosome copyWith(List<Place> newSequence) {
    return RouteChromosome(newSequence);
  }
}
