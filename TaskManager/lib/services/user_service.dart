import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api = ApiClient.instance;

  Future<List<User>> search(String q) async {
    final data = await _api.get('/users/search', query: {'q': q});
    return (data['users'] as List)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<User> getById(String id) async {
    final data = await _api.get('/users/$id');
    return User.fromJson(data['user']);
  }
}
