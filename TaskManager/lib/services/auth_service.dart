import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final AppUser user;
  AuthResult(this.token, this.user);
}

class AuthService {
  final _api = ApiClient.instance;

  AuthResult _parse(dynamic res) {
    final data = res['data'];
    return AuthResult(data['token'].toString(), AppUser.fromJson(data['user']));
  }

  Future<AuthResult> register(String fullName, String email, String password) async =>
      _parse(await _api.post('/auth/register', {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
      }));

  Future<AuthResult> login(String email, String password) async =>
      _parse(await _api.post('/auth/login', {'email': email.trim(), 'password': password}));

  Future<AppUser> me() async => AppUser.fromJson((await _api.get('/auth/me'))['data']);

  Future<AppUser> updateMe({String? fullName, String? avatarUrl}) async {
    final res = await _api.put('/auth/me', {
      if (fullName != null) 'fullName': fullName.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
    });
    return AppUser.fromJson(res['data']);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.put('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
