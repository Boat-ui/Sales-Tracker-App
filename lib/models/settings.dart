import 'dart:convert';

class AppSettings {
  double personalSavingsPercent;
  double personalUsePercent;
  String currency;

  AppSettings({
    this.personalSavingsPercent = 50,
    this.personalUsePercent = 50,
    this.currency = '₦',
  });

  // ── Firestore ──────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'personalSavingsPercent': personalSavingsPercent,
    'personalUsePercent': personalUsePercent,
    'currency': currency,
  };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
    personalSavingsPercent: (m['personalSavingsPercent'] as num).toDouble(),
    personalUsePercent: (m['personalUsePercent'] as num).toDouble(),
    currency: m['currency'] ?? '₦',
  );

  // ── Local JSON (offline fallback) ──────────────────────
  Map<String, dynamic> toJson() => {
    'personalSavingsPercent': personalSavingsPercent,
    'personalUsePercent': personalUsePercent,
    'currency': currency,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    personalSavingsPercent: (json['personalSavingsPercent'] as num).toDouble(),
    personalUsePercent: (json['personalUsePercent'] as num).toDouble(),
    currency: json['currency'] ?? '₦',
  );

  factory AppSettings.fromJsonString(String jsonStr) =>
      AppSettings.fromJson(jsonDecode(jsonStr));

  String toJsonString() => jsonEncode(toJson());
}