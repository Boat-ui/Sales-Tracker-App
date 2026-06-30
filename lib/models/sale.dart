import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String id;
  final String stockItemId;
  final String itemName;
  final double costPrice;
  final double sellingPrice;
  final int quantitySold;
  final DateTime date;
  final double personalSavingsPercent;
  final double personalUsePercent;
  final double businessPercent;
  final double personalPercent;

  Sale({
    required this.id,
    required this.stockItemId,
    required this.itemName,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantitySold,
    required this.personalSavingsPercent,
    required this.personalUsePercent,
    this.businessPercent = 50,
    this.personalPercent = 50,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  double get totalRevenue => sellingPrice * quantitySold;
  double get totalCost => costPrice * quantitySold;
  double get totalProfit => totalRevenue - totalCost;
  double get businessShare => totalProfit * (businessPercent / 100);
  double get personalShare => totalProfit * (personalPercent / 100);
  double get personalSavings => personalShare * (personalSavingsPercent / 100);
  double get personalUse => personalShare * (personalUsePercent / 100);

  // ── Firestore ──────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id': id,
    'stockItemId': stockItemId,
    'itemName': itemName,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'quantitySold': quantitySold,
    'date': Timestamp.fromDate(date),
    'personalSavingsPercent': personalSavingsPercent,
    'personalUsePercent': personalUsePercent,
    'businessPercent': businessPercent,
    'personalPercent': personalPercent,
  };

  factory Sale.fromMap(Map<String, dynamic> m) => Sale(
    id: m['id'],
    stockItemId: m['stockItemId'],
    itemName: m['itemName'],
    costPrice: (m['costPrice'] as num).toDouble(),
    sellingPrice: (m['sellingPrice'] as num).toDouble(),
    quantitySold: m['quantitySold'],
    date: m['date'] is Timestamp
        ? (m['date'] as Timestamp).toDate()
        : DateTime.parse(m['date']),
    personalSavingsPercent: (m['personalSavingsPercent'] as num).toDouble(),
    personalUsePercent: (m['personalUsePercent'] as num).toDouble(),
    businessPercent: (m['businessPercent'] as num? ?? 50).toDouble(),
    personalPercent: (m['personalPercent'] as num? ?? 50).toDouble(),
  );

  // ── Local JSON (offline fallback) ──────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'stockItemId': stockItemId,
    'itemName': itemName,
    'costPrice': costPrice,
    'sellingPrice': sellingPrice,
    'quantitySold': quantitySold,
    'date': date.toIso8601String(),
    'personalSavingsPercent': personalSavingsPercent,
    'personalUsePercent': personalUsePercent,
    'businessPercent': businessPercent,
    'personalPercent': personalPercent,
  };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'],
    stockItemId: json['stockItemId'],
    itemName: json['itemName'],
    costPrice: (json['costPrice'] as num).toDouble(),
    sellingPrice: (json['sellingPrice'] as num).toDouble(),
    quantitySold: json['quantitySold'],
    date: DateTime.parse(json['date']),
    personalSavingsPercent: (json['personalSavingsPercent'] as num).toDouble(),
    personalUsePercent: (json['personalUsePercent'] as num).toDouble(),
    businessPercent: (json['businessPercent'] as num? ?? 50).toDouble(),
    personalPercent: (json['personalPercent'] as num? ?? 50).toDouble(),
  );

  static List<Sale> listFromJson(String jsonStr) {
    final List decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Sale.fromJson(e)).toList();
  }

  static String listToJson(List<Sale> sales) {
    return jsonEncode(sales.map((e) => e.toJson()).toList());
  }
}