class Landmark {
  final String id;
  final String name;
  final int gridRow;
  final int gridCol;
  final String description;

  Landmark({
    required this.id,
    required this.name,
    required this.gridRow,
    required this.gridCol,
    required this.description,
  });

  Landmark.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      gridRow = json['grid_row'],
      gridCol = json['grid_col'],
      description = json['description'];
}
