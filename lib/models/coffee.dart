import 'dart:convert';

class Coffee {
  final String id;
  final String name;
  final String roaster;
  final String origin;
  final String flavorProfile;
  final DateTime? roastDate;
  final DateTime createdAt;
  final String? imageUrl;
  
  Coffee({
    required this.id,
    required this.name,
    this.roaster = '',
    this.origin = '',
    this.flavorProfile = '',
    this.roastDate,
    required this.createdAt,
    this.imageUrl,
  });
  
  Coffee copyWith({
    String? name,
    String? roaster,
    String? origin,
    String? flavorProfile,
    DateTime? roastDate,
    String? imageUrl,
  }) {
    return Coffee(
      id: id,
      name: name ?? this.name,
      roaster: roaster ?? this.roaster,
      origin: origin ?? this.origin,
      flavorProfile: flavorProfile ?? this.flavorProfile,
      roastDate: roastDate ?? this.roastDate,
      createdAt: createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'roaster': roaster,
      'origin': origin,
      'flavorProfile': flavorProfile,
      'roastDate': roastDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
    };
  }

  factory Coffee.fromMap(Map<String, dynamic> map) {
    return Coffee(
      id: map['id'],
      name: map['name'],
      roaster: map['roaster'] ?? '',
      origin: map['origin'] ?? '',
      flavorProfile: map['flavorProfile'] ?? '',
      roastDate: map['roastDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['roastDate']) 
        : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      imageUrl: map['imageUrl'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Coffee.fromJson(String source) => 
      Coffee.fromMap(json.decode(source));
}