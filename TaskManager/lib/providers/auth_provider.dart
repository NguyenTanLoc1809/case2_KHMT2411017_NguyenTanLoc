import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  AuthProvider() {
    // Server trả 401 khi đang có token (hết hạn) -> tự đăng xuất
    ApiClient.instance.onUnauthorized = () => logout();
  }

  /// Gọi khi mở app: khôi phục phiên đăng nhập từ token đã lưu.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    ApiClient.instance.setToken(token);
    try {
      user = await _service.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      ApiClient.instance.setToken(null);
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _saveSession(AuthResult r) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, r.token);
    ApiClient.instance.setToken(r.token);
    user = r.user;
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> login(String email, String password) async =>
      _saveSession(await _service.login(email, password));

  Future<void> register(String fullName, String email, String password) async =>
      _saveSession(await _service.register(fullName, email, password));

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    user = await _service.updateMe(fullName: fullName, avatarUrl: avatarUrl);
    notifyListeners();
  }

  Future<void> logout() async {
    if (status == AuthStatus.unauthenticated) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    ApiClient.instance.setToken(null);
    user = null;
    status = AuthStatus.unauthenticated;
    // Đóng mọi màn hình đang mở phía trên màn hình gốc
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    notifyListeners();
  }
}
