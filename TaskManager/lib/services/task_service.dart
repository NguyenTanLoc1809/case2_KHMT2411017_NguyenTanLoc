import '../models/task.dart';
import '../utils/date_formatter.dart';
import 'api_client.dart';

class TaskService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Task>> list({
    String? scope, // created | assigned | shared
    String? status,
    String? priority,
    String? q,
    String sortBy = 'createdAt',
    String order = 'desc',
  }) async {
    final query = <String, String>{
      if (scope != null && scope.isNotEmpty) 'scope': scope,
      if (status != null && status.isNotEmpty) 'status': status,
      if (priority != null && priority.isNotEmpty) 'priority': priority,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      'sortBy': sortBy,
      'order': order,
    };
    final data = await _api.get('/tasks', query: query);
    return (data['tasks'] as List)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Task> getById(String id) async {
    final data = await _api.get('/tasks/$id');
    return Task.fromJson(data['task']);
  }

  Future<Task> create({
    required String title,
    String description = '',
    DateTime? startDate,
    DateTime? dueDate,
    String priority = 'medium',
    String status = 'todo',
  }) async {
    final data = await _api.post('/tasks', body: {
      'title': title.trim(),
      'description': description.trim(),
      'startDate': DateFormatter.toIso(startDate),
      'dueDate': DateFormatter.toIso(dueDate),
      'priority': priority,
      'status': status,
    });
    return Task.fromJson(data['task']);
  }

  Future<Task> update(
    String id, {
    required String title,
    String description = '',
    DateTime? startDate,
    DateTime? dueDate,
    required String priority,
    required String status,
  }) async {
    final data = await _api.put('/tasks/$id', body: {
      'title': title.trim(),
      'description': description.trim(),
      'startDate': DateFormatter.toIso(startDate),
      'dueDate': DateFormatter.toIso(dueDate),
      'priority': priority,
      'status': status,
    });
    return Task.fromJson(data['task']);
  }

  Future<Task> updateStatus(String id, String status) async {
    final data = await _api.patch('/tasks/$id/status', body: {'status': status});
    return Task.fromJson(data['task']);
  }

  Future<void> delete(String id) => _api.delete('/tasks/$id');

  Future<List<TaskActivity>> activities(String id) async {
    final data = await _api.get('/tasks/$id/activities');
    return (data['activities'] as List)
        .map((e) => TaskActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
