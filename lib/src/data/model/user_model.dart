import '../../domain/entity/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.name,
    super.email,
    super.phone,
    required super.role,
    super.storeId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        role: json['role'] as String? ?? 'customer',
        storeId: json['storeId'] as String?,
      );
}
