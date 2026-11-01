const Task = require('../models/Task');
const asyncHandler = require('../utils/asyncHandler');
const { buildAccessFilter, serializeTasks, POPULATE } = require('../services/taskService');

const countByStatus = (rows) => {
  const out = { todo: 0, in_progress: 0, completed: 0 };
  rows.forEach((r) => { out[r._id] = r.count; });
  return { ...out, total: out.todo + out.in_progress + out.completed };
};
const groupStatus = [{ $group: { _id: '$status', count: { $sum: 1 } } }];

// Thống kê tổng số công việc (mọi công việc có quyền truy cập) theo trạng thái
exports.tasks = asyncHandler(async (req, res) => {
  const filter = await buildAccessFilter(req.user._id);
  const rows = await Task.aggregate([{ $match: filter }, ...groupStatus]);
  res.json({ success: true, data: countByStatus(rows) });
});

// Việc được giao cho tôi và việc tôi đang phụ trách chính
exports.assignments = asyncHandler(async (req, res) => {
  const me = req.user._id;
  const [assignedRows, primaryActive, createdAssignedToOthers] = await Promise.all([
    Task.aggregate([{ $match: { assigneeIds: me } }, ...groupStatus]),
    Task.countDocuments({ primaryAssigneeId: me, status: { $ne: 'completed' } }),
    Task.countDocuments({ createdBy: me, assigneeIds: { $elemMatch: { $ne: me } } }),
  ]);
  res.json({
    success: true,
    data: {
      assignedToMe: countByStatus(assignedRows),
      primaryActive,
      createdAssignedToOthers,
    },
  });
});

// Việc sắp đến hạn (trong N ngày, mặc định 3) và đã quá hạn
exports.deadlines = asyncHandler(async (req, res) => {
  const days = Math.min(Math.max(parseInt(req.query.days, 10) || 3, 1), 30);
  const now = new Date();
  const soon = new Date(now.getTime() + days * 86400000);
  const access = await buildAccessFilter(req.user._id);

  const dueSoonFilter = { $and: [access, { status: { $ne: 'completed' }, dueDate: { $gte: now, $lte: soon } }] };
  const overdueFilter = { $and: [access, { status: { $ne: 'completed' }, dueDate: { $lt: now } }] };

  const [dueSoonCount, overdueCount, dueSoon, overdue] = await Promise.all([
    Task.countDocuments(dueSoonFilter),
    Task.countDocuments(overdueFilter),
    Task.find(dueSoonFilter).sort({ dueDate: 1 }).limit(20).populate(POPULATE),
    Task.find(overdueFilter).sort({ dueDate: 1 }).limit(20).populate(POPULATE),
  ]);

  res.json({
    success: true,
    data: {
      days,
      dueSoonCount,
      overdueCount,
      dueSoon: await serializeTasks(dueSoon, req.user._id),
      overdue: await serializeTasks(overdue, req.user._id),
    },
  });
});
