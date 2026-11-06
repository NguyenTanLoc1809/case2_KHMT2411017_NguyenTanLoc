import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Goi khi mo app: doc token da luu va lay thong tin nguoi dung.
  Future<void> init() async {
    await _api.loadToken();
    if (_api.token == null) return;
    try {
      final data = await _api.get('/auth/me');
      _user = User.fromJson(data['user']);
    } on ApiException catch (e) {
      // Token het han / khong hop le -> dang xuat; loi mang -> giu token
      if (e.statusCode == 401) await _api.clearToken();
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    final data = await _api.post('/auth/register', body: {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password,
    });
    await _api.saveToken(data['token']);
    _user = User.fromJson(data['user']);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });
    await _api.saveToken(data['token']);
    _user = User.fromJson(data['user']);
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({required String fullName, String? avatarUrl}) async {
    final data = await _api.put('/auth/me', body: {
      'fullName': fullName.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
    });
    _user = User.fromJson(data['user']);
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.put('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
