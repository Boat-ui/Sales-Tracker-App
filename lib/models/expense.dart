import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

// Expense categories
enum ExpenseCategory {
  rent,
  transport,
  restock,
  utilities,
  salaries,
  marketing,
  packaging,
  food,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.rent:       return 'Rent';
      case ExpenseCategory.transport:  return 'Transport';
      case ExpenseCategory.restock:    return 'Restock';
      case ExpenseCategory.utilities:  return 'Utilities';
      case ExpenseCategory.salaries:   return 'Salaries';
      case ExpenseCategory.marketing:  return 'Marketing';
      case ExpenseCategory.packaging:  return 'Packaging';
      case ExpenseCategory.food:       return 'Food & Drinks';
      case ExpenseCategory.other:      return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.rent:       return '🏠';
      case ExpenseCategory.transport:  return '🚗';
      case ExpenseCategory.restock:    return '📦';
      case ExpenseCategory.utilities:  return '💡';
      case ExpenseCategory.salaries:   return '👥';
      case ExpenseCategory.marketing:  return '📢';
      case ExpenseCategory.packaging:  return '🛍️';
      case ExpenseCategory.food:       return '🍽️';
      case ExpenseCategory.other:      return '💸';
    }
  }
}

class Expense {
  final String id;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    this.note,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  // ── Firestore ──────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'amount': amount,
    'category': category.name,
    'date': Timestamp.fromDate(date),
    'note': note,
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'],
    description: m['description'],
    amount: (m['amount'] as num).toDouble(),
    category: ExpenseCategory.values.firstWhere(
      (e) => e.name == m['category'],
      orElse: () => ExpenseCategory.other,
    ),
    date: m['date'] is Timestamp
        ? (m['date'] as Timestamp).toDate()
        : DateTime.parse(m['date']),
    note: m['note'],
  );

  // ── Local JSON (offline fallback) ──────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'category': category.name,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'],
    description: json['description'],
    amount: (json['amount'] as num).toDouble(),
    category: ExpenseCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => ExpenseCategory.other,
    ),
    date: DateTime.parse(json['date']),
    note: json['note'],
  );

  static List<Expense> listFromJson(String jsonStr) {
    final List decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Expense.fromJson(e)).toList();
  }

  static String listToJson(List<Expense> expenses) {
    return jsonEncode(expenses.map((e) => e.toJson()).toList());
  }
}