import 'package:flutter/material.dart';

class GeneticProgressWidget extends StatelessWidget {
  final int generation;
  final int maxGenerations;
  final double bestScore;

  const GeneticProgressWidget({
    super.key,
    required this.generation,
    required this.maxGenerations,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Оптимизация GA",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "$generation / $maxGenerations",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: generation / maxGenerations,
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.straighten, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              const Text("Лучшая оценка: ", style: TextStyle(fontSize: 13)),
              Text(
                "${bestScore.toStringAsFixed(1)} мин",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
