class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? photo;
  final String role;
  final bool isActive;
  final bool isSubscribed;
  final DateTime? subscriptionExpiresAt;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photo,
    required this.role,
    this.isActive = true,
    this.isSubscribed = false,
    this.subscriptionExpiresAt,
    this.createdAt,
  });

  bool get isAgriculteur => role.toLowerCase() == 'agriculteur';
  bool get isAcheteur => role.toLowerCase() == 'acheteur';
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isTransporteur => role.toLowerCase() == 'transporteur';

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'agriculteur':
        return 'Agriculteur';
      case 'acheteur':
        return 'Acheteur';
      case 'admin':
        return 'Administrateur';
      case 'transporteur':
        return 'Transporteur';
      default:
        return role;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> rawJson) {
    // Si la réponse est enveloppée sous une clé "data" ou "user"
    final json = rawJson.containsKey('user')
        ? rawJson['user'] as Map<String, dynamic>
        : (rawJson.containsKey('data')
            ? rawJson['data'] as Map<String, dynamic>
            : rawJson);

    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      photo: json['photo'] as String?,
      role: json['role'] as String? ?? 'acheteur',
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : (json['is_active'] == 1 || json['is_active'] == '1'),
      isSubscribed: json['is_subscribed'] is bool
          ? json['is_subscribed'] as bool
          : (json['is_subscribed'] == 1 || json['is_subscribed'] == '1'),
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.tryParse(json['subscription_expires_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'role': role,
      'is_active': isActive,
      'is_subscribed': isSubscribed,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? photo,
    String? role,
    bool? isActive,
    bool? isSubscribed,
    DateTime? subscriptionExpiresAt,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
