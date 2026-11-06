import 'user.dart';

class TaskPermissions {
  final bool canEdit;
  final bool canUpdateStatus;
  final bool canDelete;
  final bool canManageSharing;

  const TaskPermissions({
    this.canEdit = false,
    this.canUpdateStatus = false,
    this.canDelete = false,
    this.canManageSharing = false,
  });

  factory TaskPermissions.fromJson(Map<String, dynamic>? j) => j == null
      ? const TaskPermissions()
      : TaskPermissions(
          canEdit: j['canEdit'] == true,
          canUpdateStatus: j['canUpdateStatus'] == true,
          canDelete: j['canDelete'] == true,
          canManageSharing: j['canManageSharing'] == true,
        );
}

class Task {
  final String id;
  final String title;
  final String description;
  final User? createdBy;
  final List<User> assignees;
  final User? primaryAssignee;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String priority; // low | medium | high
  final String status; // todo | in_progress | completed
  final DateTime? createdAt;
  final String myRole; // owner | editor | assignee | viewer
  final TaskPermissions permissions;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.createdBy,
    this.assignees = const [],
    this.primaryAssignee,
    this.startDate,
    this.dueDate,
    this.priority = 'medium',
    this.status = 'todo',
    this.createdAt,
    this.myRole = 'viewer',
    this.permissions = const TaskPermissions(),
  });

  static User? _user(dynamic v) =>
      v is Map<String, dynamic> ? User.fromJson(v) : null;

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: (j['_id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        createdBy: _user(j['createdBy']),
        assignees: ((j['assigneeIds'] ?? []) as List)
            .whereType<Map<String, dynamic>>()
            .map(User.fromJson)
            .toList(),
        primaryAssignee: _user(j['primaryAssigneeId']),
        startDate: _date(j['startDate']),
        dueDate: _date(j['dueDate']),
        priority: (j['priority'] ?? 'medium').toString(),
        status: (j['status'] ?? 'todo').toString(),
        createdAt: _date(j['createdAt']),
        myRole: (j['myRole'] ?? 'viewer').toString(),
        permissions:
            TaskPermissions.fromJson(j['permissions'] as Map<String, dynamic>?),
      );

  bool get isOverdue =>
      dueDate != null &&
      status != 'completed' &&
      dueDate!.isBefore(DateTime.now());

  String get roleLabel {
    switch (myRole) {
      case 'owner':
        return 'Người tạo';
      case 'editor':
        return 'Được chia sẻ (sửa)';
      case 'assignee':
        return 'Được giao';
      default:
        return 'Được chia sẻ (xem)';
    }
  }
}

class TaskActivity {
  final String action;
  final String userName;
  final DateTime? createdAt;
  final Map<String, dynamic> details;

  const TaskActivity({
    required this.action,
    required this.userName,
    this.createdAt,
    this.details = const {},
  });

  factory TaskActivity.fromJson(Map<String, dynamic> j) {
    final u = j['userId'];
    return TaskActivity(
      action: (j['action'] ?? '').toString(),
      userName: u is Map ? (u['fullName'] ?? '').toString() : '',
      createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()),
      details: (j['details'] is Map)
          ? Map<String, dynamic>.from(j['details'] as Map)
          : {},
    );
  }

  String get label {
    switch (action) {
      case 'created':
        return 'đã tạo công việc';
      case 'updated':
        return 'đã cập nhật thông tin';
      case 'status_changed':
        return 'đã đổi trạng thái';
      default:
        return action;
    }
  }
}

const Map<String, String> kStatusLabels = {
  'todo': 'Chưa thực hiện',
  'in_progress': 'Đang thực hiện',
  'completed': 'Đã hoàn thành',
};

const Map<String, String> kPriorityLabels = {
  'low': 'Thấp',
  'medium': 'Trung bình',
  'high': 'Cao',
};
