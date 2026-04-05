import '../data/models/Place.dart';
import '../core/genetic/genetic_optimizer.dart';
import '../core/genetic/chromosome.dart';

class MealRouteService {
  final List<Place> allPlaces;
  final GeneticOptimizer optimizer = GeneticOptimizer(
    populationSize: 100,
    mutationRate: 0.15,
    crossoverRate: 0.8,
    tournamentSize: 5,
  );

  MealRouteService(this.allPlaces);

  List<String> getAllUniqueDishes() {
    final set = <String>{};
    for (var place in allPlaces) {
      set.addAll(place.menu);
    }
    return set.toList()..sort();
  }

  RouteChromosome? findBestRoute(List<String> selectedDishes, {void Function(int gen, RouteChromosome best)? onProgress}) {
    if (selectedDishes.isEmpty) return null;

    final candidatePlaces = allPlaces.where((place) {
      return place.menu.any((dish) => selectedDishes.contains(dish));
    }).toList();

    if (candidatePlaces.isEmpty) return null;

    return optimizer.optimize(candidatePlaces, 100, onProgress: onProgress);
  }

}
