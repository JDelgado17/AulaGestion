import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_client.dart';
import '../models/domain_models.dart';

class AuthRepository {
  AuthRepository(this.client, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'aula_gestion_token';
  final ApiClient client;
  final FlutterSecureStorage _storage;

  Future<String?> restoreToken() async {
    final token = await _storage.read(key: _tokenKey);
    client.token = token;
    return token;
  }

  Future<AppUser> login(String email, String password) async {
    final data =
        Map<String, dynamic>.from(await client.post('/auth/login', body: {
      'email': email.trim().toLowerCase(),
      'password': password,
      'device_name': 'aula-gestion-flutter',
    }));
    final token = data['token'].toString();
    client.token = token;
    await _storage.write(key: _tokenKey, value: token);
    return AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<AppUser> me() async {
    final data = Map<String, dynamic>.from(await client.get('/auth/me'));
    return AppUser.fromJson(data);
  }

  Future<void> logout() async {
    try {
      if (client.token != null) await client.post('/auth/logout');
    } finally {
      client.token = null;
      await _storage.delete(key: _tokenKey);
    }
  }
}
