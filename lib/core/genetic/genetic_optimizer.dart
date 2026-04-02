import 'dart:math';
import '../../data/models/Place.dart';
import 'chromosome.dart';

class GeneticOptimizer {
  final int populationSize;
  final double mutationRate;
  final double crossoverRate;
  final int tournamentSize;

  List<RouteChromosome> _population = [];
  final Random _random = Random();

  GeneticOptimizer({
    this.populationSize = 50,
    this.mutationRate = 0.1,
    this.crossoverRate = 0.8,
    this.tournamentSize = 5,
  });

  RouteChromosome optimize(List<Place> places, int generations) {
    if (places.length < 2) return RouteChromosome(places);

    _population = _initPopulation(places);

    for (int i = 0; i < generations; i++) {
      _population = _evolve();
    }

    return _population.reduce((a, b) => a.fitness < b.fitness ? a : b);
  }

  List<RouteChromosome> _initPopulation(List<Place> places) {
    return List.generate(populationSize, (_) {
      final shuffled = List<Place>.from(places)..shuffle(_random);
      return RouteChromosome(shuffled);
    });
  }

  List<RouteChromosome> _evolve() {
    final newPopulation = <RouteChromosome>[];

    // Элитизм: сохраняем лучшего
    final best = _population.reduce((a, b) => a.fitness < b.fitness ? a : b);
    newPopulation.add(best);

    while (newPopulation.length < populationSize) {
      final p1 = _tournamentSelection();
      final p2 = _tournamentSelection();

      RouteChromosome child;
      if (_random.nextDouble() < crossoverRate) {
        child = _orderCrossover(p1, p2);
      } else {
        child = p1;
      }

      if (_random.nextDouble() < mutationRate) {
        child = _swapMutation(child);
      }

      newPopulation.add(child);
    }

    return newPopulation;
  }

  RouteChromosome _tournamentSelection() {
    final tournament = List.generate(
      tournamentSize,
      (_) => _population[_random.nextInt(_population.length)],
    );
    return tournament.reduce((a, b) => a.fitness < b.fitness ? a : b);
  }

  RouteChromosome _orderCrossover(RouteChromosome p1, RouteChromosome p2) {
    final s1 = p1.sequence;
    final s2 = p2.sequence;
    final len = s1.length;

    final start = _random.nextInt(len);
    final end = _random.nextInt(len - start) + start;

    final childSeq = List<Place?>.filled(len, null);
    
    // Копируем сегмент от первого родителя
    for (int i = start; i <= end; i++) {
      childSeq[i] = s1[i];
    }

    // Заполняем остальное из второго родителя, сохраняя порядок
    int childIdx = (end + 1) % len;
    int parentIdx = (end + 1) % len;

    while (childSeq.contains(null)) {
      final item = s2[parentIdx];
      if (!childSeq.contains(item)) {
        childSeq[childIdx] = item;
        childIdx = (childIdx + 1) % len;
      }
      parentIdx = (parentIdx + 1) % len;
    }

    return RouteChromosome(childSeq.cast<Place>().toList());
  }

  RouteChromosome _swapMutation(RouteChromosome chromosome) {
    final sequence = List<Place>.from(chromosome.sequence);
    final idx1 = _random.nextInt(sequence.length);
    final idx2 = _random.nextInt(sequence.length);

    final tmp = sequence[idx1];
    sequence[idx1] = sequence[idx2];
    sequence[idx2] = tmp;

    return RouteChromosome(sequence);
  }
}
