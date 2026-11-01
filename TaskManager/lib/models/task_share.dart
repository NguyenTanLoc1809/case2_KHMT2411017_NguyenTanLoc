import 'user.dart';

class TaskShare {
  final String id;
  final String taskId;
  final AppUser user;
  final String permission; // viewer | editor
  final AppUser? sharedBy;
  final DateTime? createdAt;

  const TaskShare({
    required this.id,
    required this.taskId,
    required this.user,
    required this.permission,
    this.sharedBy,
    this.createdAt,
  });

  factory TaskShare.fromJson(Map<String, dynamic> j) => TaskShare(
        id: j['_id'].toString(),
        taskId: j['taskId'].toString(),
        user: AppUser.fromJson(j['userId']),
        permission: (j['permission'] ?? 'viewer').toString(),
        sharedBy: j['sharedBy'] != null ? AppUser.fromJson(j['sharedBy']) : null,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString())?.toLocal() : null,
      );
}
