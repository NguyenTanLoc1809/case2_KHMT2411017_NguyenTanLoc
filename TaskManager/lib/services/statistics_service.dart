import '../models/task.dart';
import 'api_client.dart';

class StatusCounts {
  final int todo, inProgress, completed, total;
  const StatusCounts(this.todo, this.inProgress, this.completed, this.total);

  factory StatusCounts.fromJson(Map<String, dynamic> j) => StatusCounts(
        (j['todo'] as num?)?.toInt() ?? 0,
        (j['in_progress'] as num?)?.toInt() ?? 0,
        (j['completed'] as num?)?.toInt() ?? 0,
        (j['total'] as num?)?.toInt() ?? 0,
      );
}

class AssignmentStats {
  final StatusCounts assignedToMe;
  final int primaryActive;
  final int createdAssignedToOthers;
  const AssignmentStats(this.assignedToMe, this.primaryActive, this.createdAssignedToOthers);
}

class DeadlineStats {
  final int days, dueSoonCount, overdueCount;
  final List<Task> dueSoon, overdue;
  const DeadlineStats(this.days, this.dueSoonCount, this.overdueCount, this.dueSoon, this.overdue);
}

class AllStatistics {
  final StatusCounts tasks;
  final AssignmentStats assignments;
  final DeadlineStats deadlines;
  const AllStatistics(this.tasks, this.assignments, this.deadlines);
}

class StatisticsService {
  final _api = ApiClient.instance;

  Future<StatusCounts> tasks() async =>
      StatusCounts.fromJson(Map<String, dynamic>.from((await _api.get('/statistics/tasks'))['data']));

  Future<AssignmentStats> assignments() async {
    final d = Map<String, dynamic>.from((await _api.get('/statistics/assignments'))['data']);
    return AssignmentStats(
      StatusCounts.fromJson(Map<String, dynamic>.from(d['assignedToMe'])),
      (d['primaryActive'] as num).toInt(),
      (d['createdAssignedToOthers'] as num).toInt(),
    );
  }

  Future<DeadlineStats> deadlines() async {
    final d = Map<String, dynamic>.from((await _api.get('/statistics/deadlines'))['data']);
    List<Task> parse(dynamic l) =>
        (l as List).map((e) => Task.fromJson(Map<String, dynamic>.from(e))).toList();
    return DeadlineStats(
      (d['days'] as num).toInt(),
      (d['dueSoonCount'] as num).toInt(),
      (d['overdueCount'] as num).toInt(),
      parse(d['dueSoon']),
      parse(d['overdue']),
    );
  }

  Future<AllStatistics> all() async {
    final results = await Future.wait([tasks(), assignments(), deadlines()]);
    return AllStatistics(
      results[0] as StatusCounts,
      results[1] as AssignmentStats,
      results[2] as DeadlineStats,
    );
  }
}
