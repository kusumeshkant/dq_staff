import '../../domain/entity/user_entity.dart';
import '../../domain/repo/auth_repository.dart';
import '../datasources/remote/auth_remote_ds.dart';
import '../model/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDs ds;
  AuthRepositoryImpl(this.ds);

  @override
  Future<void> loginWithEmail(String email, String password) =>
      ds.loginWithEmail(email, password);

  @override
  Future<void> registerWithEmail(String email, String password) =>
      ds.registerWithEmail(email, password);

  @override
  Future<UserEntity> getProfile() async {
    final json = await ds.getProfile();
    return UserModel.fromJson(json);
  }

  @override
  Future<void> updateProfileName(String name) => ds.updateProfileName(name);

  @override
  Future<void> updateFcmToken(String token) => ds.updateFcmToken(token);

  @override
  Future<void> signOut() => ds.signOut();
}
