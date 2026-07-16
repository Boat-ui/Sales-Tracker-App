import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtStatus { unpaid, partiallyPaid, paid }

class DebtPayment {
  final double amount;
  final DateTime date;
  final String? note;

  DebtPayment({required this.amount, required this.date, this.note});

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'note': note,
  };

  factory DebtPayment.fromMap(Map<String, dynamic> m) => DebtPayment(
    amount: (m['amount'] as num).toDouble(),
    date: m['date'] is Timestamp ? (m['date'] as Timestamp).toDate() : DateTime.parse(m['date']),
    note: m['note'],
  );

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory DebtPayment.fromJson(Map<String, dynamic> j) => DebtPayment(
    amount: (j['amount'] as num).toDouble(),
    date: DateTime.parse(j['date']),
    note: j['note'],
  );
}

class Debt {
  final String id;
  final String customerName;
  final String? customerPhone;
  final double totalAmount;
  final DateTime date;
  final String? note;
  final String? stockItemId;   // null if free entry
  final String? stockItemName;
  final int? quantitySold;
  final List<DebtPayment> payments;

  Debt({
    required this.id,
    required this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.payments,
    this.note,
    this.stockItemId,
    this.stockItemName,
    this.quantitySold,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  double get totalPaid => payments.fold(0.0, (a, p) => a + p.amount);
  double get balance   => totalAmount - totalPaid;

  DebtStatus get status {
    if (balance <= 0) return DebtStatus.paid;
    if (totalPaid > 0) return DebtStatus.partiallyPaid;
    return DebtStatus.unpaid;
  }

  bool get isLinkedToStock => stockItemId != null;

  // ── Firestore ──────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id': id,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'totalAmount': totalAmount,
    'date': Timestamp.fromDate(date),
    'note': note,
    'stockItemId': stockItemId,
    'stockItemName': stockItemName,
    'quantitySold': quantitySold,
    'payments': payments.map((p) => p.toMap()).toList(),
  };

  factory Debt.fromMap(Map<String, dynamic> m) => Debt(
    id: m['id'],
    customerName: m['customerName'],
    customerPhone: m['customerPhone'],
    totalAmount: (m['totalAmount'] as num).toDouble(),
    date: m['date'] is Timestamp ? (m['date'] as Timestamp).toDate() : DateTime.parse(m['date']),
    note: m['note'],
    stockItemId: m['stockItemId'],
    stockItemName: m['stockItemName'],
    quantitySold: m['quantitySold'],
    payments: (m['payments'] as List? ?? []).map((p) => DebtPayment.fromMap(p as Map<String, dynamic>)).toList(),
  );

  // ── Local JSON ─────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'totalAmount': totalAmount,
    'date': date.toIso8601String(),
    'note': note,
    'stockItemId': stockItemId,
    'stockItemName': stockItemName,
    'quantitySold': quantitySold,
    'payments': payments.map((p) => p.toJson()).toList(),
  };

  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
    id: j['id'],
    customerName: j['customerName'],
    customerPhone: j['customerPhone'],
    totalAmount: (j['totalAmount'] as num).toDouble(),
    date: DateTime.parse(j['date']),
    note: j['note'],
    stockItemId: j['stockItemId'],
    stockItemName: j['stockItemName'],
    quantitySold: j['quantitySold'],
    payments: (j['payments'] as List? ?? []).map((p) => DebtPayment.fromJson(p as Map<String, dynamic>)).toList(),
  );

  static List<Debt> listFromJson(String jsonStr) {
    final List decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Debt.fromJson(e)).toList();
  }

  static String listToJson(List<Debt> debts) {
    return jsonEncode(debts.map((e) => e.toJson()).toList());
  }

  // Returns a copy with a new payment added
  Debt withPayment(DebtPayment payment) => Debt(
    id: id,
    customerName: customerName,
    customerPhone: customerPhone,
    totalAmount: totalAmount,
    date: date,
    note: note,
    stockItemId: stockItemId,
    stockItemName: stockItemName,
    quantitySold: quantitySold,
    payments: [...payments, payment],
  );
}