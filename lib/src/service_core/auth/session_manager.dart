import 'package:get/get.dart';
import '../../domain/entity/store_entity.dart';
import '../../domain/entity/user_entity.dart';

class SessionManager extends GetxService {
  final Rx<UserEntity?> currentUser = Rx<UserEntity?>(null);
  final Rx<StoreEntity?> currentStore = Rx<StoreEntity?>(null);

  bool get isLoggedIn => currentUser.value != null;
  String? get storeId => currentUser.value?.storeId;
  String? get staffName => currentUser.value?.name;
  String? get staffId => currentUser.value?.id;

  void setUser(UserEntity user) => currentUser.value = user;
  void setStore(StoreEntity store) => currentStore.value = store;

  void clearUser() {
    currentUser.value = null;
    currentStore.value = null;
  }
}
