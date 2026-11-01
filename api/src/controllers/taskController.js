const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const TaskActivity = require('../models/TaskActivity');
const Notification = require('../models/Notification');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/ApiError');
const tpl = require('../utils/emailTemplates');
const { escapeRegex, STATUS_LABEL, formatDateTimeVN, sameDate } = require('../utils/helpers');
const {
  POPULATE, buildAccessFilter, serializeTasks, loadTaskDto, getParticipants, logActivity,
} = require('../services/taskService');
const { dispatch } = require('../services/notificationService');

const SORT_FIELDS = { dueDate: 'dueDate', priority: 'priorityRank', createdAt: 'createdAt' };

function setStatus(task, status) {
  task.status = status;
  task.completedAt = status === 'completed' ? new Date() : null;
}

// Ghi lịch sử + thông báo sau khi đổi trạng thái (email chỉ gửi khi hoàn thành)
async function afterStatusChange(task, from, actor) {
  await logActivity(task._id, actor._id, 'status_changed', { from, to: task.status });
  const recipients = await getParticipants(task);
  if (task.status === 'completed') {
    await dispatch({
      task, actor, recipients, type: 'task_completed',
      title: 'Công việc đã hoàn thành',
      message: `${actor.fullName} đã hoàn thành công việc "${task.title}"`,
      email: (user) => tpl.taskCompleted({ user, task, actor }),
    });
  } else {
    await dispatch({
      task, actor, recipients, type: 'status_changed',
      title: 'Trạng thái công việc thay đổi',
      message: `${actor.fullName} đã chuyển "${task.title}" sang "${STATUS_LABEL[task.status]}"`,
      email: null,
    });
  }
}

exports.listTasks = asyncHandler(async (req, res) => {
  const { scope, status, priority, q, assigneeId, sortBy = 'createdAt', order = 'desc' } = req.query;
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 100);

  const conditions = [await buildAccessFilter(req.user._id, scope)];
  if (status) conditions.push({ status });
  if (priority) conditions.push({ priority });
  if (assigneeId) conditions.push({ assigneeIds: assigneeId });
  if (q && q.trim()) conditions.push({ title: { $regex: escapeRegex(q.trim().slice(0, 100)), $options: 'i' } });
  const filter = { $and: conditions };

  const sort = { [SORT_FIELDS[sortBy] || 'createdAt']: order === 'asc' ? 1 : -1, _id: -1 };
  const [tasks, total] = await Promise.all([
    Task.find(filter).sort(sort).skip((page - 1) * limit).limit(limit).populate(POPULATE),
    Task.countDocuments(filter),
  ]);

  res.json({
    success: true,
    data: await serializeTasks(tasks, req.user._id),
    pagination: { page, limit, total },
  });
});

exports.createTask = asyncHandler(async (req, res) => {
  const { title, description = '', startDate, dueDate, priority = 'medium', status = 'todo' } = req.body;
  const task = await Task.create({
    title,
    description: description || '',
    startDate: startDate || null,
    dueDate,
    priority,
    status,
    completedAt: status === 'completed' ? new Date() : null,
    createdBy: req.user._id,
  });
  await logActivity(task._id, req.user._id, 'created', { title });
  res.status(201).json({
    success: true,
    message: 'Tạo công việc thành công',
    data: await loadTaskDto(task._id, req.user._id),
  });
});

exports.getTask = asyncHandler(async (req, res) => {
  res.json({ success: true, data: await loadTaskDto(req.task._id, req.user._id) });
});

exports.updateTask = asyncHandler(async (req, res) => {
  const task = req.task;
  const actor = req.user;
  const body = req.body;
  const changes = {};

  ['title', 'description', 'priority'].forEach((f) => {
    const nv = body[f] === null ? '' : body[f];
    if (nv !== undefined && nv !== task[f]) {
      changes[f] = { from: task[f], to: nv };
      task[f] = nv;
    }
  });

  const oldDue = task.dueDate;
  let dueChanged = false;
  if (body.startDate !== undefined) {
    const nv = body.startDate ? new Date(body.startDate) : null;
    if (!sameDate(task.startDate, nv)) {
      changes.startDate = { from: task.startDate, to: nv };
      task.startDate = nv;
    }
  }
  if (body.dueDate !== undefined) {
    const nv = new Date(body.dueDate);
    if (!sameDate(task.dueDate, nv)) {
      changes.dueDate = { from: task.dueDate, to: nv };
      task.dueDate = nv;
      task.reminderSentAt = null; // hạn mới -> cho phép nhắc lại
      dueChanged = true;
    }
  }
  if (task.startDate && task.dueDate < task.startDate) {
    throw new ApiError(400, 'Hạn hoàn thành phải sau hoặc bằng ngày bắt đầu');
  }

  let statusFrom = null;
  if (body.status !== undefined && body.status !== task.status) {
    statusFrom = task.status;
    setStatus(task, body.status);
  }

  if (Object.keys(changes).length || statusFrom) {
    await task.save();
    if (Object.keys(changes).length) await logActivity(task._id, actor._id, 'updated', { changes });

    if (dueChanged) {
      await dispatch({
        task, actor, recipients: await getParticipants(task), type: 'due_date_changed',
        title: 'Hạn hoàn thành thay đổi',
        message: `Hạn của "${task.title}" đổi từ ${formatDateTimeVN(oldDue)} sang ${formatDateTimeVN(task.dueDate)}`,
        email: (user) => tpl.dueDateChanged({ user, task, actor, oldDue, newDue: task.dueDate }),
      });
    }
    if (statusFrom) await afterStatusChange(task, statusFrom, actor);
  }

  res.json({
    success: true,
    message: 'Cập nhật công việc thành công',
    data: await loadTaskDto(task._id, actor._id),
  });
});

exports.updateStatus = asyncHandler(async (req, res) => {
  const task = req.task;
  const from = task.status;
  if (req.body.status !== from) {
    setStatus(task, req.body.status);
    await task.save();
    await afterStatusChange(task, from, req.user);
  }
  res.json({
    success: true,
    message: 'Cập nhật trạng thái thành công',
    data: await loadTaskDto(task._id, req.user._id),
  });
});

exports.deleteTask = asyncHandler(async (req, res) => {
  const taskId = req.task._id;
  await Promise.all([
    TaskShare.deleteMany({ taskId }),
    TaskActivity.deleteMany({ taskId }),
    Notification.deleteMany({ taskId }),
    req.task.deleteOne(),
  ]);
  res.json({ success: true, message: 'Đã xóa công việc' });
});

exports.getActivities = asyncHandler(async (req, res) => {
  const activities = await TaskActivity.find({ taskId: req.task._id })
    .sort({ createdAt: -1 })
    .limit(100)
    .populate('userId', 'fullName email avatarUrl');
  res.json({ success: true, data: activities });
});
