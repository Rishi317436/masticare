class CattleModel {
  const CattleModel({
    this.id,
    required this.userId,
    required this.name,
    this.breed,
    this.age,
    this.sex,
    this.imagePath,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int userId;
  final String name;
  final String? breed;
  final int? age;
  final String? sex;
  final String? imagePath;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'breed': breed,
      'age': age,
      'sex': sex,
      'image_path': imagePath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CattleModel.fromMap(Map<String, dynamic> map) {
    return CattleModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      breed: map['breed'] as String?,
      age: map['age'] as int?,
      sex: map['sex'] as String?,
      imagePath: map['image_path'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }
}
