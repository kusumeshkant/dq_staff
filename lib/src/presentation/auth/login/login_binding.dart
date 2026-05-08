import 'package:get/get.dart';
import '../../../data/datasources/remote/auth_remote_ds.dart';
import '../../../data/repo_impl/auth_repository_impl.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    final repo = AuthRepositoryImpl(AuthRemoteDs());
    Get.lazyPut(() => LoginController(authRepo: repo));
  }
}
