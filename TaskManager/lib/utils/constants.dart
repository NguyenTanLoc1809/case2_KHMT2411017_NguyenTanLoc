import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Dùng để đưa người dùng về màn hình gốc khi đăng xuất / hết phiên đăng nhập.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppConstants {
  /// Có thể ghi đè khi chạy: flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) return env;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api'; // máy ảo Android
    }
    return 'http://localhost:3000/api'; // iOS simulator / web / desktop
  }

  static const String tokenKey = 'auth_token';

  static const List<String> statuses = ['todo', 'in_progress', 'completed'];
  static const List<String> priorities = ['low', 'medium', 'high'];

  static const Map<String, String> statusLabels = {
    'todo': 'Chưa thực hiện',
    'in_progress': 'Đang thực hiện',
    'completed': 'Đã hoàn thành',
  };
  static const Map<String, String> priorityLabels = {
    'low': 'Thấp',
    'medium': 'Trung bình',
    'high': 'Cao',
  };
  static const Map<String, Color> statusColors = {
    'todo': Colors.blueGrey,
    'in_progress': Colors.blue,
    'completed': Colors.green,
  };
  static const Map<String, Color> priorityColors = {
    'low': Colors.teal,
    'medium': Colors.orange,
    'high': Colors.red,
  };
  static const Map<String, String> permissionLabels = {
    'viewer': 'Chỉ xem',
    'editor': 'Chỉnh sửa',
  };
  static const Map<String, String> roleLabels = {
    'owner': 'Người tạo',
    'assignee': 'Được giao',
    'viewer': 'Chỉ xem',
    'editor': 'Chỉnh sửa',
  };
}
