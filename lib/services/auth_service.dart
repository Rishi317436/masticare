import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'session_service.dart';

class AuthResult {
  const AuthResult({required this.success, this.userId, this.message});

  final bool success;
  final int? userId;
  final String? message;

  bool get isSuccess => success;
}

class AuthService {
  AuthService({UserRepository? repository}) : _repository = repository ?? UserRepository();

  final UserRepository _repository;

  static const int _saltLength = 16;

  Future<AuthResult> signIn({required String email, required String password}) async {
    await DatabaseHelper.instance.database;

    final normalizedEmail = email.trim().toLowerCase();
    final existingUser = await _repository.getUserByEmail(normalizedEmail);
    if (existingUser == null) {
      return const AuthResult(success: false, message: 'Invalid email or password.');
    }

    final storedHash = existingUser.passwordHash;
    final parts = storedHash.split(':');
    if (parts.length != 2) {
      return const AuthResult(success: false, message: 'Invalid email or password.');
    }

    final salt = parts.first;
    final expectedHash = '$salt:${_hashPassword(password, salt)}';

    if (storedHash == expectedHash) {
      if (existingUser.id == null) {
        return const AuthResult(success: false, message: 'User session could not be restored.');
      }
      await SessionService.instance.saveSession(existingUser.id!);
      return AuthResult(success: true, userId: existingUser.id, message: 'Signed in successfully.');
    }

    return const AuthResult(success: false, message: 'Invalid email or password.');
  }

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String location,
  }) async {
    await DatabaseHelper.instance.database;

    final normalizedEmail = email.trim().toLowerCase();
    final existingUser = await _repository.getUserByEmail(normalizedEmail);
    if (existingUser != null) {
      return const AuthResult(success: false, message: 'An account with this email already exists.');
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);
    final user = UserModel(
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      role: role,
      location: location.trim(),
      passwordHash: '$salt:$passwordHash',
      createdAt: DateTime.now(),
    );

    final userId = await _repository.createUser(user);
    await SessionService.instance.saveSession(userId);

    return AuthResult(success: true, userId: userId, message: 'Account created successfully.');
  }

  Future<int?> getCurrentUserId() async {
    return SessionService.instance.getSessionUserId();
  }

  Future<void> logout() async {
    await SessionService.instance.clearSession();
  }

  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
