class UserModel {
  const UserModel({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.location,
    required this.passwordHash,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? location;
  final String passwordHash;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'location': location,
      'password_hash': passwordHash,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      role: map['role'] as String?,
      location: map['location'] as String?,
      passwordHash: map['password_hash'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }
}
