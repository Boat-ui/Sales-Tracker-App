import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // ── Firestore ──────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'costPrice': costPrice,
    'quantity': quantity,
    'category': category,
    'dateAdded': Timestamp.fromDate(dateAdded),
  };

  factory StockItem.fromMap(Map<String, dynamic> m) => StockItem(
    id: m['id'],
    name: m['name'],
    costPrice: (m['costPrice'] as num).toDouble(),
    quantity: m['quantity'],
    category: m['category'],
    dateAdded: m['dateAdded'] is Timestamp
        ? (m['dateAdded'] as Timestamp).toDate()
        : DateTime.parse(m['dateAdded']),
  );

  // ── Local JSON (offline fallback) ──────────────────────
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