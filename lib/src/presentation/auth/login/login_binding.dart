import 'package:get/get.dart';
import '../../../data/datasources/remote/auth_remote_ds.dart';
import '../../../data/repo_impl/auth_repository_impl.dart';
import '../../../domain/usecase/get_profile_usecase.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    final ds = AuthRemoteDs();
    final repo = AuthRepositoryImpl(ds);
    Get.lazyPut(() => LoginController(
          authRepo: repo,
          getProfileUseCase: GetProfileUseCase(repo),
        ));
  }
}
