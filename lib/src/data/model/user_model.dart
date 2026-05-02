import '../../domain/entity/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.name,
    super.email,
    super.phone,
    required super.role,
    super.roles = const ['customer'],
    super.storeId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final List<String> roles = rawRoles is List
        ? rawRoles.map((e) => e.toString()).toList()
        : [json['role'] as String? ?? 'customer'];

    String role = 'customer';
    if (roles.contains('admin')) role = 'admin';
    else if (roles.contains('staff')) role = 'staff';

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: role,
      roles: roles,
      storeId: json['storeId'] as String?,
    );
  }
}
