import 'package:get/get.dart';
import '../../../data/datasources/remote/auth_remote_ds.dart';
import '../../../data/repo_impl/auth_repository_impl.dart';
import 'register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    final ds = AuthRemoteDs();
    final repo = AuthRepositoryImpl(ds);
    Get.lazyPut(() => RegisterController(authRepo: repo));
  }
}
