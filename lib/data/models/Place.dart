class Place {
  final String id;
  final String name;
  final String type;
  final int gridRow;
  final int gridCol;
  final String openTime;
  final String closeTime;
  final String priceLevel;
  final List<String> menu;

  Place({
    required this.id,
    required this.name,
    required this.type,
    required this.gridRow,
    required this.gridCol,
    required this.openTime,
    required this.closeTime,
    required this.priceLevel,
    required this.menu,
  });

  Place.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      type = json['type'],
      gridRow = json['grid_row'],
      gridCol = json['grid_col'],
      openTime = json['open_time'],
      closeTime = json['close_time'],
      priceLevel = json['price_level'],
      menu = List<String>.from(json['menu']);
}
