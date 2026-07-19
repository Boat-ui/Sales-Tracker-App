import 'package:cloud_firestore/cloud_firestore.dart';

enum BusinessType {
  retail,
  food,
  farm,
  service;

  String get label {
    switch (this) {
      case BusinessType.retail:  return 'Retail / Resale';
      case BusinessType.food:    return 'Food / Production';
      case BusinessType.farm:    return 'Farm / Agriculture';
      case BusinessType.service: return 'Service';
    }
  }

  String get emoji {
    switch (this) {
      case BusinessType.retail:  return '🛍️';
      case BusinessType.food:    return '🍳';
      case BusinessType.farm:    return '🌾';
      case BusinessType.service: return '💼';
    }
  }

  String get description {
    switch (this) {
      case BusinessType.retail:  return 'Buy items and sell them — clothes, phones, groceries, etc.';
      case BusinessType.food:    return 'Cook with ingredients and sell portions or meals';
      case BusinessType.farm:    return 'Invest over time and sell harvests by weight or quantity';
      case BusinessType.service: return 'Sell your skills or time — hair, repairs, delivery, etc.';
    }
  }
}

class Business {
  final String id;
  final String name;
  final BusinessType type;
  final String ownerId;
  final DateTime createdAt;
  final Map<String, String> members; // uid -> role ('owner','manager','cashier')

  Business({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.createdAt,
    this.members = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'ownerId': ownerId,
    'createdAt': Timestamp.fromDate(createdAt),
    'members': members,
  };

  factory Business.fromMap(Map<String, dynamic> m) => Business(
    id: m['id'],
    name: m['name'],
    type: BusinessType.values.firstWhere(
      (t) => t.name == m['type'],
      orElse: () => BusinessType.retail,
    ),
    ownerId: m['ownerId'],
    createdAt: m['createdAt'] is Timestamp
        ? (m['createdAt'] as Timestamp).toDate()
        : DateTime.parse(m['createdAt']),
    members: Map<String, String>.from(m['members'] ?? {}),
  );

  Business copyWith({String? name, BusinessType? type, Map<String, String>? members}) => Business(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    ownerId: ownerId,
    createdAt: createdAt,
    members: members ?? this.members,
  );
}