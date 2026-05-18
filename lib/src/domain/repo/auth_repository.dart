import '../entity/store_entity.dart';
import '../entity/user_entity.dart';

abstract class AuthRepository {
  Future<void> loginWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password);
  Future<UserEntity> getProfile();
  Future<UserEntity> validateAppAccess();
  Future<StoreEntity?> getStoreById(String id);
  Future<void> updateProfileName(String name);
  Future<void> updateFcmToken(String token);
  Future<void> registerInBackend(String name);
  Future<void> signOut();
}
