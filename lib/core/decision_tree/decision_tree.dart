import 'dart:math';

class DecisionTreeSample {
  final Map<String, String> features;
  final String label;

  const DecisionTreeSample({required this.features, required this.label});
}

class DecisionPathStep {
  final String feature;
  final String value;

  const DecisionPathStep({required this.feature, required this.value});
}

class DecisionTreePrediction {
  final String label;
  final List<DecisionPathStep> path;

  const DecisionTreePrediction({required this.label, required this.path});
}

class DecisionTreeNode {
  final bool isLeaf;
  final String? label;
  final String? splitFeature;
  final Map<String, DecisionTreeNode> children;
  final String fallbackLabel;

  const DecisionTreeNode._({
    required this.isLeaf,
    required this.label,
    required this.splitFeature,
    required this.children,
    required this.fallbackLabel,
  });

  factory DecisionTreeNode.leaf(String label) {
    return DecisionTreeNode._(
      isLeaf: true,
      label: label,
      splitFeature: null,
      children: const {},
      fallbackLabel: label,
    );
  }

  factory DecisionTreeNode.branch({
    required String splitFeature,
    required Map<String, DecisionTreeNode> children,
    required String fallbackLabel,
  }) {
    return DecisionTreeNode._(
      isLeaf: false,
      label: null,
      splitFeature: splitFeature,
      children: children,
      fallbackLabel: fallbackLabel,
    );
  }
}

class DecisionTreeModel {
  final DecisionTreeNode root;
  final List<String> featureOrder;
  final Map<String, List<String>> featureValues;

  const DecisionTreeModel({
    required this.root,
    required this.featureOrder,
    required this.featureValues,
  });
}

class DecisionTreeTrainOptions {
  final int? maxDepth;
  final double minInformationGain;

  const DecisionTreeTrainOptions({
    this.maxDepth,
    this.minInformationGain = 1e-9,
  });
}

class DecisionTreeStats {
  final int nodeCount;
  final int leafCount;
  final int depth;

  const DecisionTreeStats({
    required this.nodeCount,
    required this.leafCount,
    required this.depth,
  });
}

class DecisionTreeClassifier {
  DecisionTreeModel train(
    List<DecisionTreeSample> samples, {
    DecisionTreeTrainOptions options = const DecisionTreeTrainOptions(),
  }) {
    if (samples.isEmpty) {
      throw const FormatException('Обучающая выборка пуста');
    }

    final featureOrder = samples.first.features.keys.toList();
    if (featureOrder.isEmpty) {
      throw const FormatException('В выборке нет признаков');
    }

    final featureValues = <String, Set<String>>{
      for (final f in featureOrder) f: <String>{},
    };
    for (final sample in samples) {
      for (final f in featureOrder) {
        final value = sample.features[f] ?? '';
        featureValues[f]!.add(value);
      }
    }

    final root = _buildTree(
      samples: samples,
      features: featureOrder,
      options: options,
      depth: 0,
    );

    return DecisionTreeModel(
      root: root,
      featureOrder: featureOrder,
      featureValues: {
        for (final entry in featureValues.entries)
          entry.key: entry.value.toList()..sort(),
      },
    );
  }

  DecisionTreePrediction predict({
    required DecisionTreeModel model,
    required Map<String, String> features,
  }) {
    final path = <DecisionPathStep>[];
    var node = model.root;

    while (!node.isLeaf) {
      final feature = node.splitFeature!;
      final value = features[feature] ?? '';
      path.add(DecisionPathStep(feature: feature, value: value));
      node = node.children[value] ?? DecisionTreeNode.leaf(node.fallbackLabel);
    }

    return DecisionTreePrediction(label: node.label!, path: path);
  }

  DecisionTreeNode _buildTree({
    required List<DecisionTreeSample> samples,
    required List<String> features,
    required DecisionTreeTrainOptions options,
    required int depth,
  }) {
    final majority = _majorityLabel(samples);
    if (_allSameLabel(samples)) {
      return DecisionTreeNode.leaf(samples.first.label);
    }
    if (options.maxDepth != null && depth >= options.maxDepth!) {
      return DecisionTreeNode.leaf(majority);
    }
    if (features.isEmpty) {
      return DecisionTreeNode.leaf(majority);
    }

    final bestSplit = _bestFeatureByGain(samples, features);
    final bestFeature = bestSplit.$1;
    final bestGain = bestSplit.$2;
    if (bestFeature == null || bestGain < options.minInformationGain) {
      return DecisionTreeNode.leaf(majority);
    }

    final partitions = <String, List<DecisionTreeSample>>{};
    for (final sample in samples) {
      final value = sample.features[bestFeature] ?? '';
      partitions.putIfAbsent(value, () => <DecisionTreeSample>[]).add(sample);
    }

    final nextFeatures = features.where((f) => f != bestFeature).toList();
    final children = <String, DecisionTreeNode>{};
    for (final entry in partitions.entries) {
      children[entry.key] = _buildTree(
        samples: entry.value,
        features: nextFeatures,
        options: options,
        depth: depth + 1,
      );
    }

    return DecisionTreeNode.branch(
      splitFeature: bestFeature,
      children: children,
      fallbackLabel: majority,
    );
  }

  (String?, double) _bestFeatureByGain(
    List<DecisionTreeSample> samples,
    List<String> features,
  ) {
    final baseEntropy = _entropy(samples);
    String? bestFeature;
    var bestGain = 0.0;

    for (final feature in features) {
      final subsets = <String, List<DecisionTreeSample>>{};
      for (final sample in samples) {
        final value = sample.features[feature] ?? '';
        subsets.putIfAbsent(value, () => <DecisionTreeSample>[]).add(sample);
      }

      var weightedEntropy = 0.0;
      for (final subset in subsets.values) {
        final p = subset.length / samples.length;
        weightedEntropy += p * _entropy(subset);
      }
      final gain = baseEntropy - weightedEntropy;
      if (gain > bestGain) {
        bestGain = gain;
        bestFeature = feature;
      }
    }

    return (bestFeature, bestGain);
  }

  double _entropy(List<DecisionTreeSample> samples) {
    final counts = <String, int>{};
    for (final sample in samples) {
      counts[sample.label] = (counts[sample.label] ?? 0) + 1;
    }
    var result = 0.0;
    for (final count in counts.values) {
      final p = count / samples.length;
      result -= p * (log(p) / ln2);
    }
    return result;
  }

  bool _allSameLabel(List<DecisionTreeSample> samples) {
    final first = samples.first.label;
    for (final sample in samples) {
      if (sample.label != first) {
        return false;
      }
    }
    return true;
  }

  String _majorityLabel(List<DecisionTreeSample> samples) {
    final counts = <String, int>{};
    for (final sample in samples) {
      counts[sample.label] = (counts[sample.label] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

DecisionTreeStats analyzeTree(DecisionTreeNode root) {
  int nodeCount = 0;
  int leafCount = 0;
  int maxDepth = 0;

  void visit(DecisionTreeNode node, int depth) {
    nodeCount++;
    if (node.isLeaf) {
      leafCount++;
    }
    if (depth > maxDepth) {
      maxDepth = depth;
    }
    for (final child in node.children.values) {
      visit(child, depth + 1);
    }
  }

  visit(root, 1);
  return DecisionTreeStats(
    nodeCount: nodeCount,
    leafCount: leafCount,
    depth: maxDepth,
  );
}

List<DecisionTreeSample> parseDecisionTreeCsv(
  String csv, {
  String targetColumn = 'recommended_place',
}) {
  final lines = csv
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.length < 2) {
    throw const FormatException(
      'CSV должен содержать заголовок и хотя бы 1 строку',
    );
  }

  final headers = lines.first.split(',').map((h) => h.trim()).toList();
  final targetIndex = headers.indexOf(targetColumn);
  if (targetIndex < 0) {
    throw FormatException('Не найден целевой столбец: $targetColumn');
  }

  final samples = <DecisionTreeSample>[];
  for (int i = 1; i < lines.length; i++) {
    final cols = lines[i].split(',').map((c) => c.trim()).toList();
    if (cols.length != headers.length) {
      throw FormatException(
        'Строка ${i + 1}: ожидалось ${headers.length} колонок, получено ${cols.length}',
      );
    }
    final label = cols[targetIndex];
    if (label.isEmpty) {
      throw FormatException('Строка ${i + 1}: пустой target');
    }

    final features = <String, String>{};
    for (int j = 0; j < headers.length; j++) {
      if (j == targetIndex) {
        continue;
      }
      features[headers[j]] = cols[j];
    }

    samples.add(DecisionTreeSample(features: features, label: label));
  }

  return samples;
}

String treeToPrettyText(DecisionTreeNode node, {String indent = ''}) {
  if (node.isLeaf) {
    return '$indent=> ${node.label}';
  }
  final b = StringBuffer();
  b.writeln('$indent[${node.splitFeature}]');
  for (final entry in node.children.entries) {
    b.writeln('$indent  ${entry.key}:');
    b.writeln(treeToPrettyText(entry.value, indent: '$indent    '));
  }
  return b.toString().trimRight();
}
