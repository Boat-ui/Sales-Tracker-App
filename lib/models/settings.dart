import 'dart:convert';

class AppSettings {
  double businessPercent;       // % of profit going to business
  double personalPercent;       // % of profit going to personal (= 100 - businessPercent)
  double personalSavingsPercent; // % of personal share going to savings
  double personalUsePercent;    // % of personal share going to spending
  String currency;

  AppSettings({
    this.businessPercent = 50,
    this.personalPercent = 50,
    this.personalSavingsPercent = 50,
    this.personalUsePercent = 50,
    this.currency = '₦',
  });

  // ── Firestore ──────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'businessPercent': businessPercent,
    'personalPercent': personalPercent,
    'personalSavingsPercent': personalSavingsPercent,
    'personalUsePercent': personalUsePercent,
    'currency': currency,
  };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
    businessPercent: (m['businessPercent'] as num? ?? 50).toDouble(),
    personalPercent: (m['personalPercent'] as num? ?? 50).toDouble(),
    personalSavingsPercent: (m['personalSavingsPercent'] as num).toDouble(),
    personalUsePercent: (m['personalUsePercent'] as num).toDouble(),
    currency: m['currency'] ?? '₦',
  );

  // ── Local JSON (offline fallback) ──────────────────────
  Map<String, dynamic> toJson() => {
    'businessPercent': businessPercent,
    'personalPercent': personalPercent,
    'personalSavingsPercent': personalSavingsPercent,
    'personalUsePercent': personalUsePercent,
    'currency': currency,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    businessPercent: (json['businessPercent'] as num? ?? 50).toDouble(),
    personalPercent: (json['personalPercent'] as num? ?? 50).toDouble(),
    personalSavingsPercent: (json['personalSavingsPercent'] as num).toDouble(),
    personalUsePercent: (json['personalUsePercent'] as num).toDouble(),
    currency: json['currency'] ?? '₦',
  );

  factory AppSettings.fromJsonString(String jsonStr) =>
      AppSettings.fromJson(jsonDecode(jsonStr));

  String toJsonString() => jsonEncode(toJson());
}