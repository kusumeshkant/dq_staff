class UserEntity {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String role;
  final List<String> roles;
  final String? storeId;

  const UserEntity({
    required this.id,
    this.name,
    this.email,
    this.phone,
    required this.role,
    this.roles = const ['customer'],
    this.storeId,
  });

  bool get isStaff => roles.contains('staff');
  bool get isAdmin => roles.contains('admin');
  bool get isCustomer => roles.contains('customer');
}
