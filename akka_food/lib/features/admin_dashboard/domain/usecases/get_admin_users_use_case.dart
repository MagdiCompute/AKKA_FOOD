import '../entities/admin_user_view.dart';
import '../repositories/i_admin_user_repository.dart';

/// Returns a real-time stream of all registered users for the admin dashboard.
class GetAdminUsersUseCase {
  const GetAdminUsersUseCase(this._repository);
  final IAdminUserRepository _repository;

  Stream<List<AdminUserView>> call() => _repository.watchAllUsers();
}
