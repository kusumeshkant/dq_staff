import '../entity/user_entity.dart';
import '../repo/auth_repository.dart';

class GetProfileUseCase {
  final AuthRepository repo;
  GetProfileUseCase(this.repo);

  Future<UserEntity> execute() => repo.getProfile();
}
