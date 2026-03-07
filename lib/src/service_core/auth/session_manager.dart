import 'package:get/get.dart';
import '../../domain/entity/user_entity.dart';

class SessionManager extends GetxService {
  final Rx<UserEntity?> currentUser = Rx<UserEntity?>(null);

  bool get isLoggedIn => currentUser.value != null;
  String? get storeId => currentUser.value?.storeId;
  String? get staffName => currentUser.value?.name;
  String? get staffId => currentUser.value?.id;

  void setUser(UserEntity user) => currentUser.value = user;
  void clearUser() => currentUser.value = null;
}
