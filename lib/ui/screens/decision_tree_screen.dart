import 'package:flutter/material.dart';

import '../../core/decision_tree/decision_tree.dart';

class DecisionTreeScreen extends StatefulWidget {
  const DecisionTreeScreen({super.key});

  @override
  State<DecisionTreeScreen> createState() => _DecisionTreeScreenState();
}

class _DecisionTreeScreenState extends State<DecisionTreeScreen> {
  final DecisionTreeClassifier _classifier = DecisionTreeClassifier();
  final TextEditingController _csvController = TextEditingController(
    text: _defaultCsv,
  );

  DecisionTreeModel? _model;
  Map<String, String> _selectedFeatures = {};
  DecisionTreePrediction? _prediction;
  String? _error;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  void _trainModel() {
    try {
      final samples = parseDecisionTreeCsv(_csvController.text);
      final model = _classifier.train(samples);
      final features = <String, String>{};
      for (final f in model.featureOrder) {
        final values = model.featureValues[f] ?? const <String>[];
        features[f] = values.isNotEmpty ? values.first : '';
      }

      setState(() {
        _model = model;
        _selectedFeatures = features;
        _prediction = null;
        _error = null;
      });
      _predict();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _predict() {
    if (_model == null) {
      return;
    }
    final prediction = _classifier.predict(
      model: _model!,
      features: _selectedFeatures,
    );
    setState(() {
      _prediction = prediction;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дерево решений (ID3)')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'Обучающая выборка (CSV)',
                icon: Icons.dataset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _csvController,
                      minLines: 8,
                      maxLines: 14,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'location,budget,...,recommended_place',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _trainModel,
                          icon: const Icon(Icons.account_tree),
                          label: const Text('Обучить дерево'),
                        ),
                        const SizedBox(width: 8),
                        if (_model != null)
                          OutlinedButton.icon(
                            onPressed: _predict,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Пересчитать'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              if (_model != null) ...[
                _buildSectionCard(
                  title: 'Ввод признаков',
                  icon: Icons.tune,
                  child: Column(
                    children: _model!.featureOrder.map((feature) {
                      final values =
                          _model!.featureValues[feature] ?? const <String>[];
                      final selected = _selectedFeatures[feature] ?? '';
                      final effective =
                          values.contains(selected) && selected.isNotEmpty
                          ? selected
                          : (values.isNotEmpty ? values.first : '');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: effective.isEmpty
                                    ? null
                                    : effective,
                                items: values
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(v),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedFeatures[feature] = value;
                                  });
                                  _predict();
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_prediction != null) ...[
                  _buildSectionCard(
                    title: 'Результат',
                    icon: Icons.check_circle_outline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF005AAB,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Рекомендованное место: ${_prediction!.label}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF005AAB),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Путь по дереву:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        ..._prediction!.path.map(
                          (step) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.subdirectory_arrow_right,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${step.feature} = ${step.value}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildSectionCard(
                  title: 'Граф дерева',
                  icon: Icons.hub,
                  child: _DecisionNodeGraph(node: _model!.root, isRoot: true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF005AAB)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DecisionNodeGraph extends StatelessWidget {
  final DecisionTreeNode node;
  final String? edgeLabel;
  final bool isRoot;

  const _DecisionNodeGraph({
    required this.node,
    this.edgeLabel,
    this.isRoot = false,
  });

  @override
  Widget build(BuildContext context) {
    final childrenEntries = node.children.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isRoot && edgeLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Chip(
              label: Text(edgeLabel!, style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: node.isLeaf
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: node.isLeaf ? Colors.green : Colors.orange,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                node.isLeaf ? Icons.flag : Icons.call_split,
                size: 16,
                color: node.isLeaf ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  node.isLeaf
                      ? 'Класс: ${node.label}'
                      : 'Признак: ${node.splitFeature}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (childrenEntries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: Column(
              children: childrenEntries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 42,
                        child: CustomPaint(painter: _EdgePainter()),
                      ),
                      Expanded(
                        child: _DecisionNodeGraph(
                          node: entry.value,
                          edgeLabel: entry.key,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final start = Offset(size.width / 2, 0);
    final mid = Offset(size.width / 2, size.height / 2);
    final end = Offset(size.width, size.height / 2);
    canvas.drawLine(start, mid, paint);
    canvas.drawLine(mid, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const String _defaultCsv = '''
location,budget,time_available,food_type,queue_tolerance,weather,recommended_place
main_building,low,medium,full_meal,medium,good,Main_Cafeteria
main_building,low,short,snack,low,good,Yarche
main_building,medium,short,coffee,low,good,Bus_Stop_Coffee
main_building,high,medium,coffee,medium,good,Starbooks
second_building,low,very_short,snack,low,good,Vending_Machine
second_building,medium,short,coffee,medium,good,Second_Building_Cafe
second_building,medium,medium,full_meal,medium,good,Main_Cafeteria
second_building,low,short,snack,low,bad,Vending_Machine
campus_center,medium,short,pancakes,medium,good,Siberian_Pancakes
bus_stop,medium,short,coffee,low,good,Bus_Stop_Coffee
''';
