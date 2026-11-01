import '../models/task_share.dart';
import 'api_client.dart';

class TaskShareService {
  final _api = ApiClient.instance;

  List<TaskShare> _list(dynamic res) =>
      (res['data'] as List).map((e) => TaskShare.fromJson(Map<String, dynamic>.from(e))).toList();

  Future<List<TaskShare>> getShares(String taskId) async => _list(await _api.get('/tasks/$taskId/shares'));

  Future<List<TaskShare>> share(String taskId, List<String> userIds, String permission) async =>
      _list(await _api.post('/tasks/$taskId/shares', {'userIds': userIds, 'permission': permission}));

  Future<List<TaskShare>> updatePermission(String taskId, String shareId, String permission) async =>
      _list(await _api.patch('/tasks/$taskId/shares/$shareId', {'permission': permission}));

  Future<List<TaskShare>> revoke(String taskId, String shareId) async =>
      _list(await _api.delete('/tasks/$taskId/shares/$shareId'));
}
