import '../utils/constants.dart';
import 'user.dart';

class TaskActivity {
  final String id;
  final AppUser user;
  final String action;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  const TaskActivity({
    required this.id,
    required this.user,
    required this.action,
    required this.details,
    required this.createdAt,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> j) => TaskActivity(
        id: j['_id'].toString(),
        user: AppUser.fromJson(j['userId']),
        action: (j['action'] ?? '').toString(),
        details: Map<String, dynamic>.from((j['details'] as Map?) ?? const {}),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      );

  /// Mô tả hoạt động bằng tiếng Việt.
  String get description {
    switch (action) {
      case 'created':
        return 'đã tạo công việc';
      case 'updated':
        final changes = (details['changes'] as Map?)?.keys.map(_fieldLabel).join(', ');
        return 'đã cập nhật ${changes ?? 'thông tin'}';
      case 'status_changed':
        final from = AppConstants.statusLabels[details['from']] ?? details['from'];
        final to = AppConstants.statusLabels[details['to']] ?? details['to'];
        return 'đã đổi trạng thái từ "$from" sang "$to"';
      case 'assigned':
        return 'đã giao việc cho ${_names(details['users'])}';
      case 'unassigned':
        return 'đã hủy giao việc của một người';
      case 'primary_changed':
        return 'đã thay đổi người phụ trách chính';
      case 'shared':
        return 'đã chia sẻ cho ${details['user'] ?? 'một người'} '
            '(${AppConstants.permissionLabels[details['permission']] ?? ''})';
      case 'share_updated':
        return 'đã đổi quyền chia sẻ thành "${AppConstants.permissionLabels[details['permission']] ?? ''}"';
      case 'share_revoked':
        return 'đã thu hồi quyền chia sẻ của một người';
      default:
        return action;
    }
  }

  static String _names(dynamic v) =>
      v is List && v.isNotEmpty ? v.map((e) => e.toString()).join(', ') : 'một người';

  static String _fieldLabel(String f) {
    switch (f) {
      case 'title':
        return 'tên';
      case 'description':
        return 'mô tả';
      case 'priority':
        return 'mức độ ưu tiên';
      case 'startDate':
        return 'ngày bắt đầu';
      case 'dueDate':
        return 'hạn hoàn thành';
      default:
        return f;
    }
  }
}
