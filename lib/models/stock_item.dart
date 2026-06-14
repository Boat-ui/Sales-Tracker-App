import 'dart:convert';

class StockItem {
  final String id;
  String name;
  double costPrice;
  int quantity;
  String? category;
  DateTime dateAdded;

  StockItem({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.quantity,
    this.category,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'costPrice': costPrice,
        'quantity': quantity,
        'category': category,
        'dateAdded': dateAdded.toIso8601String(),
      };

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        id: json['id'],
        name: json['name'],
        costPrice: (json['costPrice'] as num).toDouble(),
        quantity: json['quantity'],
        category: json['category'],
        dateAdded: DateTime.parse(json['dateAdded']),
      );

  static List<StockItem> listFromJson(String jsonStr) {
    final List decoded = jsonDecode(jsonStr);
    return decoded.map((e) => StockItem.fromJson(e)).toList();
  }

  static String listToJson(List<StockItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}
