import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  int unread = 0;

  Future<void> refresh() async {
    try {
      unread = await _service.unreadCount();
      notifyListeners();
    } catch (_) {
      // bỏ qua lỗi mạng: chỉ ảnh hưởng số badge
    }
  }

  void setUnread(int value) {
    unread = value < 0 ? 0 : value;
    notifyListeners();
  }
}
