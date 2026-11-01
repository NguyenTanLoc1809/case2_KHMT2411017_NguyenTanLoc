import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  final _api = ApiClient.instance;

  Future<List<AppNotification>> getNotifications() async {
    final res = await _api.get('/notifications', query: {'limit': 100});
    return (res['data'] as List).map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<int> unreadCount() async {
    final res = await _api.get('/notifications/unread-count');
    return (res['data']['count'] as num).toInt();
  }

  Future<void> markRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.patch('/notifications/read-all');
  }
}
