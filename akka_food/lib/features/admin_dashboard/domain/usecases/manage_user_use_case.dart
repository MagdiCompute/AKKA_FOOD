import '../repositories/i_admin_user_repository.dart';

/// Deactivates or reactivates a user account via the admin Cloud Function.
class ManageUserUseCase {
  const ManageUserUseCase(this._repository);
  final IAdminUserRepository _repository;

  Future<void> deactivate(String uid) => _repository.deactivateUser(uid);
  Future<void> reactivate(String uid) => _repository.reactivateUser(uid);
}
