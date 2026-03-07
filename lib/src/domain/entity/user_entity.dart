class UserEntity {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String role;
  final String? storeId;

  const UserEntity({
    required this.id,
    this.name,
    this.email,
    this.phone,
    required this.role,
    this.storeId,
  });

  bool get isStaff => role == 'staff';
  bool get isAdmin => role == 'admin';
}
