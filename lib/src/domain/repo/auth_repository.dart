import '../entity/user_entity.dart';

abstract class AuthRepository {
  Future<void> loginWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password);
  Future<UserEntity> getProfile();
  Future<void> updateProfileName(String name);
  Future<void> updateFcmToken(String token);
  Future<void> signOut();
}
