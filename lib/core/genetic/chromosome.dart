import '../../data/models/Place.dart';
import 'dart:math';

class RouteChromosome {
  final List<Place> sequence;
  double? _fitness;

  RouteChromosome(this.sequence);

  double get fitness {
    if (_fitness == null) {
      _fitness = _calculateFitness();
    }
    return _fitness!;
  }

  double _calculateFitness() {
    if (sequence.isEmpty) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 0; i < sequence.length - 1; i++) {
      totalDistance += _distance(sequence[i], sequence[i + 1]);
    }
    
    // В GA для минимизации мы часто используем 1/расстояние, 
    // но здесь мы можем просто минимизировать расстояние напрямую в селекции.
    return totalDistance;
  }

  double _distance(Place a, Place b) {
    // Используем Евклидово расстояние для быстрых расчетов в GA. 
    // Точный путь по A* будет рассчитан только для финального результата.
    return sqrt(pow(a.gridCol - b.gridCol, 2) + pow(a.gridRow - b.gridRow, 2));
  }

  RouteChromosome copyWith(List<Place> newSequence) {
    return RouteChromosome(newSequence);
  }
}
