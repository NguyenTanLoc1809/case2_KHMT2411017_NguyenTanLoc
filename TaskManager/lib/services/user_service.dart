import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final _api = ApiClient.instance;

  Future<List<AppUser>> search(String q) async {
    final res = await _api.get('/users/search', query: {'q': q});
    return (res['data'] as List).map((e) => AppUser.fromJson(e)).toList();
  }
}
