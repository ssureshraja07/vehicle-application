import '../entities/user_entity.dart';

abstract class UserSearchRepository {
  Future<List<UserEntity>> getUsersByRole(String role, {String city});
}
