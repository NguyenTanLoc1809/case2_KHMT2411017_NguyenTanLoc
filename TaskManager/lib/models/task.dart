import 'user.dart';

DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

class Task {
  final String id;
  final String title;
  final String description;
  final AppUser? createdBy;
  final List<AppUser> assignees;
  final AppUser? primaryAssignee;
  final DateTime? startDate;
  final DateTime dueDate;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final String? myRole; // owner | assignee | editor | viewer
  final bool canEdit;
  final bool canDelete;
  final bool canManage;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.assignees,
    required this.primaryAssignee,
    required this.startDate,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.myRole,
    required this.canEdit,
    required this.canDelete,
    required this.canManage,
  });

  factory Task.fromJson(Map<String, dynamic> j) {
    final perms = (j['permissions'] as Map?) ?? const {};
    return Task(
      id: j['_id'].toString(),
      title: (j['title'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      createdBy: j['createdBy'] != null ? AppUser.fromJson(j['createdBy']) : null,
      assignees: ((j['assignees'] as List?) ?? const []).map((e) => AppUser.fromJson(e)).toList(),
      primaryAssignee:
          j['primaryAssignee'] != null ? AppUser.fromJson(j['primaryAssignee']) : null,
      startDate: _parseDate(j['startDate']),
      dueDate: _parseDate(j['dueDate']) ?? DateTime.now(),
      priority: (j['priority'] ?? 'medium').toString(),
      status: (j['status'] ?? 'todo').toString(),
      createdAt: _parseDate(j['createdAt']),
      myRole: j['myRole']?.toString(),
      canEdit: perms['canEdit'] == true,
      canDelete: perms['canDelete'] == true,
      canManage: perms['canManage'] == true,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());
}
