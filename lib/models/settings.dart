import 'dart:convert';

class AppSettings {
  double businessPercent;
  double personalPercent;
  double personalSavingsPercent;
  double personalUsePercent;
  String currency;
  int lowStockThreshold; // notify when item quantity <= this

  AppSettings({
    this.businessPercent = 50,
    this.personalPercent = 50,
    this.personalSavingsPercent = 50,
    this.personalUsePercent = 50,
    this.currency = '₦',
    this.lowStockThreshold = 2,
  });

  // ── Firestore ──────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'businessPercent': businessPercent,
    'personalPercent': personalPercent,
    'personalSavingsPercent': personalSavingsPercent,
    'personalUsePercent': personalUsePercent,
    'currency': currency,
    'lowStockThreshold': lowStockThreshold,
  };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
    businessPercent: (m['businessPercent'] as num? ?? 50).toDouble(),
    personalPercent: (m['personalPercent'] as num? ?? 50).toDouble(),
    personalSavingsPercent: (m['personalSavingsPercent'] as num? ?? 50).toDouble(),
    personalUsePercent: (m['personalUsePercent'] as num? ?? 50).toDouble(),
    currency: m['currency'] ?? '₦',
    lowStockThreshold: (m['lowStockThreshold'] as num? ?? 2).toInt(),
  );

  // ── Local JSON (offline fallback) ──────────────────────
  Map<String, dynamic> toJson() => {
    'businessPercent': businessPercent,
    'personalPercent': personalPercent,
    'personalSavingsPercent': personalSavingsPercent,
    'personalUsePercent': personalUsePercent,
    'currency': currency,
    'lowStockThreshold': lowStockThreshold,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    businessPercent: (json['businessPercent'] as num? ?? 50).toDouble(),
    personalPercent: (json['personalPercent'] as num? ?? 50).toDouble(),
    personalSavingsPercent: (json['personalSavingsPercent'] as num? ?? 50).toDouble(),
    personalUsePercent: (json['personalUsePercent'] as num? ?? 50).toDouble(),
    currency: json['currency'] ?? '₦',
    lowStockThreshold: (json['lowStockThreshold'] as num? ?? 2).toInt(),
  );

  factory AppSettings.fromJsonString(String jsonStr) =>
      AppSettings.fromJson(jsonDecode(jsonStr));

  String toJsonString() => jsonEncode(toJson());
}