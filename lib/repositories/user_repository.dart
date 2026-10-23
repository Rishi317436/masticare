import '../database/dao/user_dao.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository({UserDao? dao}) : _dao = dao ?? UserDao();

  final UserDao _dao;

  Future<int> createUser(UserModel user) async {
    final row = user.toMap();
    row.remove('id');
    return _dao.insertUser(row);
  }

  Future<List<UserModel>> getUsers() async {
    final rows = await _dao.fetchUsers();
    return rows.map(UserModel.fromMap).toList();
  }

  Future<UserModel?> getUserById(int id) async {
    final row = await _dao.getUserById(id);
    if (row == null) return null;
    return UserModel.fromMap(row);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final row = await _dao.getUserByEmail(email);
    if (row == null) return null;
    return UserModel.fromMap(row);
  }
}
