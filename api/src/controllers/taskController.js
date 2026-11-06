const mongoose = require('mongoose');
const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const TaskActivity = require('../models/TaskActivity');
const AppError = require('../utils/AppError');
const asyncHandler = require('../utils/asyncHandler');
const { resolveRole, logActivity, serializeTask, POPULATE } = require('../services/taskService');

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const PRIORITY_WEIGHT = { low: 1, medium: 2, high: 3 };
const toDate = (v) => (v === null || v === '' ? null : new Date(v));

// GET /api/tasks?scope=created|assigned|shared&status=&priority=&q=&assigneeId=&sortBy=&order=
exports.listTasks = asyncHandler(async (req, res) => {
  const { scope, status, priority, q, assigneeId, sortBy = 'createdAt', order = 'desc' } = req.query;
  const uid = req.user._id;

  // Cac ban ghi chia se cua toi
  const myShares = await TaskShare.find({ userId: uid });
  const sharedIds = myShares.map((s) => s.taskId);

  // Pham vi truy cap theo scope
  const scopeConditions = {
    created: { createdBy: uid },
    assigned: { assigneeIds: uid },
    shared: { _id: { $in: sharedIds } },
  };
  const access =
    scope && scopeConditions[scope]
      ? scopeConditions[scope]
      : { $or: [{ createdBy: uid }, { assigneeIds: uid }, { _id: { $in: sharedIds } }] };

  const filter = { $and: [access] };
  if (status) filter.$and.push({ status });
  if (priority) filter.$and.push({ priority });
  if (q && q.toString().trim()) {
    filter.$and.push({ title: new RegExp(escapeRegex(q.toString().trim()), 'i') });
  }
  if (assigneeId) {
    if (!mongoose.isValidObjectId(assigneeId)) throw new AppError('assigneeId khong hop le', 400);
    filter.$and.push({ $or: [{ primaryAssigneeId: assigneeId }, { assigneeIds: assigneeId }] });
  }

  const dir = order === 'asc' ? 1 : -1;
  const allowedSort = ['dueDate', 'priority', 'createdAt'];
  const sortField = allowedSort.includes(sortBy) ? sortBy : 'createdAt';

  let query = Task.find(filter).populate(POPULATE);
  if (sortField !== 'priority') {
    // Cong viec khong co han (null) luon xep cuoi khi sap theo dueDate
    query = query.sort({ [sortField]: dir, _id: -1 });
  }
  let tasks = await query;

  if (sortField === 'priority') {
    tasks.sort((a, b) => (PRIORITY_WEIGHT[a.priority] - PRIORITY_WEIGHT[b.priority]) * dir);
  } else if (sortField === 'dueDate') {
    const withDue = tasks.filter((t) => t.dueDate);
    const noDue = tasks.filter((t) => !t.dueDate);
    tasks = [...withDue, ...noDue];
  }

  const shareMap = new Map(myShares.map((s) => [String(s.taskId), s]));
  const data = tasks.map((t) => serializeTask(t, resolveRole(t, uid, shareMap.get(String(t._id)))));

  res.json({ success: true, data: { tasks: data, total: data.length } });
});

// POST /api/tasks
exports.createTask = asyncHandler(async (req, res) => {
  const { title, description, startDate, dueDate, priority, status } = req.body;

  const task = await Task.create({
    title: title.trim(),
    description: description ? description.trim() : '',
    createdBy: req.user._id,
    startDate: toDate(startDate) || null,
    dueDate: toDate(dueDate) || null,
    priority: priority || 'medium',
    status: status || 'todo',
  });
  await task.populate(POPULATE);
  await logActivity(task._id, req.user._id, 'created', { title: task.title });

  res.status(201).json({
    success: true,
    message: 'Tao cong viec thanh cong',
    data: { task: serializeTask(task, 'owner') },
  });
});

// GET /api/tasks/:id   (requireTaskPermission('view'))
exports.getTask = asyncHandler(async (req, res) => {
  res.json({ success: true, data: { task: serializeTask(req.task, req.taskRole) } });
});

// PUT /api/tasks/:id   (requireTaskPermission('edit'))
exports.updateTask = asyncHandler(async (req, res) => {
  const task = req.task;
  const changes = {};
  const set = (field, value) => {
    const oldVal = task[field];
    const same = String(oldVal ?? '') === String(value ?? '');
    if (!same) {
      changes[field] = { from: oldVal ?? null, to: value ?? null };
      task[field] = value;
    }
  };

  const b = req.body;
  if (b.title !== undefined) set('title', b.title.trim());
  if (b.description !== undefined) set('description', b.description.trim());
  if (b.priority !== undefined) set('priority', b.priority);
  if (b.status !== undefined) set('status', b.status);
  if (b.startDate !== undefined) set('startDate', toDate(b.startDate));
  if (b.dueDate !== undefined) set('dueDate', toDate(b.dueDate));

  if (task.startDate && task.dueDate && task.dueDate < task.startDate) {
    throw new AppError('Han hoan thanh phai sau hoac bang ngay bat dau', 400);
  }

  if (Object.keys(changes).length > 0) {
    await task.save();
    await logActivity(task._id, req.user._id, 'updated', { changes });
  }
  await task.populate(POPULATE);

  res.json({
    success: true,
    message: 'Cap nhat cong viec thanh cong',
    data: { task: serializeTask(task, req.taskRole) },
  });
});

// PATCH /api/tasks/:id/status   (requireTaskPermission('status'))
exports.updateStatus = asyncHandler(async (req, res) => {
  const task = req.task;
  const newStatus = req.body.status;

  if (task.status !== newStatus) {
    const oldStatus = task.status;
    task.status = newStatus;
    await task.save();
    await logActivity(task._id, req.user._id, 'status_changed', { from: oldStatus, to: newStatus });
  }
  await task.populate(POPULATE);

  res.json({
    success: true,
    message: 'Cap nhat trang thai thanh cong',
    data: { task: serializeTask(task, req.taskRole) },
  });
});

// DELETE /api/tasks/:id   (requireTaskPermission('delete') -> chi nguoi tao)
exports.deleteTask = asyncHandler(async (req, res) => {
  const id = req.task._id;
  await Promise.all([
    Task.deleteOne({ _id: id }),
    TaskShare.deleteMany({ taskId: id }),
    TaskActivity.deleteMany({ taskId: id }),
  ]);
  res.json({ success: true, message: 'Xoa cong viec thanh cong' });
});

// GET /api/tasks/:id/activities   (requireTaskPermission('view'))
exports.getActivities = asyncHandler(async (req, res) => {
  const activities = await TaskActivity.find({ taskId: req.task._id })
    .sort({ createdAt: -1 })
    .limit(100)
    .populate('userId', 'fullName email');
  res.json({ success: true, data: { activities } });
});
