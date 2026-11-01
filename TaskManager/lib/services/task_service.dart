import '../models/email_log.dart';
import '../models/task.dart';
import '../models/task_activity.dart';
import 'api_client.dart';

/// Bộ lọc / tìm kiếm / sắp xếp danh sách công việc.
class TaskFilter {
  String scope; // '' (tất cả) | created | assigned | shared
  String? status;
  String? priority;
  String? q;
  String? assigneeId;
  String? assigneeName;
  String sortBy; // dueDate | priority | createdAt
  String order; // asc | desc

  TaskFilter({
    this.scope = '',
    this.status,
    this.priority,
    this.q,
    this.assigneeId,
    this.assigneeName,
    this.sortBy = 'createdAt',
    this.order = 'desc',
  });

  TaskFilter copy() => TaskFilter(
        scope: scope,
        status: status,
        priority: priority,
        q: q,
        assigneeId: assigneeId,
        assigneeName: assigneeName,
        sortBy: sortBy,
        order: order,
      );

  bool get hasActiveFilter =>
      status != null || priority != null || assigneeId != null || sortBy != 'createdAt' || order != 'desc';

  Map<String, dynamic> toQuery() => {
        'scope': scope,
        'status': status,
        'priority': priority,
        'q': q?.trim(),
        'assigneeId': assigneeId,
        'sortBy': sortBy,
        'order': order,
        'limit': 100,
      };
}

class TaskService {
  final _api = ApiClient.instance;

  Task _task(dynamic res) => Task.fromJson(Map<String, dynamic>.from(res['data']));

  Future<List<Task>> getTasks(TaskFilter filter) async {
    final res = await _api.get('/tasks', query: filter.toQuery());
    return (res['data'] as List).map((e) => Task.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<Task> getTask(String id) async => _task(await _api.get('/tasks/$id'));

  Future<Task> createTask(Map<String, dynamic> body) async => _task(await _api.post('/tasks', body));

  Future<Task> updateTask(String id, Map<String, dynamic> body) async =>
      _task(await _api.put('/tasks/$id', body));

  Future<void> deleteTask(String id) async {
    await _api.delete('/tasks/$id');
  }

  Future<Task> updateStatus(String id, String status) async =>
      _task(await _api.patch('/tasks/$id/status', {'status': status}));

  Future<List<TaskActivity>> getActivities(String id) async {
    final res = await _api.get('/tasks/$id/activities');
    return (res['data'] as List).map((e) => TaskActivity.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // ----- Giao việc -----
  Future<Task> assign(String id, {required List<String> userIds, String? primaryAssigneeId}) async =>
      _task(await _api.post('/tasks/$id/assignees', {
        'userIds': userIds,
        if (primaryAssigneeId != null) 'primaryAssigneeId': primaryAssigneeId,
      }));

  Future<Task> setPrimary(String id, String userId, bool isPrimary) async =>
      _task(await _api.patch('/tasks/$id/assignees/$userId', {'isPrimary': isPrimary}));

  Future<Task> unassign(String id, String userId) async =>
      _task(await _api.delete('/tasks/$id/assignees/$userId'));

  // ----- Email -----
  Future<List<EmailLog>> getEmailLogs(String id) async {
    final res = await _api.get('/tasks/$id/email-logs');
    return (res['data'] as List).map((e) => EmailLog.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> retryEmail(String logId) async {
    await _api.post('/email-logs/$logId/retry');
  }
}
