const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/ApiError');
const tpl = require('../utils/emailTemplates');
const {
  loadTaskDto, resolveUsers, logActivity, idEq,
} = require('../services/taskService');
const { dispatch } = require('../services/notificationService');

const isAssignee = (task, userId) => task.assigneeIds.some((a) => idEq(a, userId));

exports.list = asyncHandler(async (req, res) => {
  const dto = await loadTaskDto(req.task._id, req.user._id);
  res.json({
    success: true,
    data: dto.assignees.map((u) => ({
      ...u,
      isPrimary: !!dto.primaryAssignee && idEq(dto.primaryAssignee._id, u._id),
    })),
  });
});

exports.assign = asyncHandler(async (req, res) => {
  const task = req.task;
  const actor = req.user;
  const { userIds = [], emails = [], primaryAssigneeId } = req.body;
  if (!userIds.length && !emails.length) throw new ApiError(400, 'Cần chọn ít nhất một người để giao việc');

  const { users, notFoundEmails } = await resolveUsers({ userIds, emails });
  if (!users.length) throw new ApiError(404, 'Không tìm thấy người dùng phù hợp');

  const newUsers = users.filter((u) => !isAssignee(task, u._id));
  newUsers.forEach((u) => task.assigneeIds.push(u._id));

  let primaryChanged = false;
  if (primaryAssigneeId) {
    if (!isAssignee(task, primaryAssigneeId)) {
      throw new ApiError(400, 'Người phụ trách chính phải nằm trong danh sách người được giao');
    }
    if (!idEq(task.primaryAssigneeId, primaryAssigneeId)) {
      task.primaryAssigneeId = primaryAssigneeId;
      primaryChanged = true;
    }
  } else if (!task.primaryAssigneeId && task.assigneeIds.length) {
    task.primaryAssigneeId = task.assigneeIds[0];
    primaryChanged = true;
  }

  if (newUsers.length || primaryChanged) await task.save();

  if (newUsers.length) {
    await logActivity(task._id, actor._id, 'assigned', { users: newUsers.map((u) => u.fullName) });
    await dispatch({
      task, actor, recipients: newUsers, type: 'task_assigned',
      title: 'Bạn được giao công việc mới',
      message: `${actor.fullName} đã giao cho bạn công việc "${task.title}"`,
      email: (user) => tpl.taskAssigned({ user, task, actor }),
    });
  }
  if (primaryChanged) {
    await logActivity(task._id, actor._id, 'primary_changed', { userId: String(task.primaryAssigneeId) });
  }

  res.json({
    success: true,
    message: newUsers.length ? 'Giao việc thành công' : 'Không có người mới để giao',
    data: await loadTaskDto(task._id, actor._id),
    notFoundEmails,
  });
});

exports.setPrimary = asyncHandler(async (req, res) => {
  const task = req.task;
  const { userId } = req.params;
  if (!isAssignee(task, userId)) throw new ApiError(404, 'Người này chưa được giao công việc');

  if (req.body.isPrimary) {
    if (!idEq(task.primaryAssigneeId, userId)) {
      task.primaryAssigneeId = userId;
      await task.save();
      await logActivity(task._id, req.user._id, 'primary_changed', { userId });
    }
  } else if (idEq(task.primaryAssigneeId, userId)) {
    task.primaryAssigneeId = null;
    await task.save();
    await logActivity(task._id, req.user._id, 'primary_changed', { userId: null });
  }
  res.json({
    success: true,
    message: 'Cập nhật người phụ trách thành công',
    data: await loadTaskDto(task._id, req.user._id),
  });
});

exports.unassign = asyncHandler(async (req, res) => {
  const task = req.task;
  const { userId } = req.params;
  if (!isAssignee(task, userId)) throw new ApiError(404, 'Người này chưa được giao công việc');

  task.assigneeIds = task.assigneeIds.filter((a) => !idEq(a, userId));
  if (idEq(task.primaryAssigneeId, userId)) {
    task.primaryAssigneeId = task.assigneeIds[0] || null; // chuyển cho người kế tiếp (nếu có)
  }
  await task.save();
  await logActivity(task._id, req.user._id, 'unassigned', { userId });

  const removed = await User.findById(userId).select('fullName email');
  if (removed) {
    await dispatch({
      task, actor: req.user, recipients: [removed], type: 'task_unassigned',
      title: 'Bạn đã bị hủy giao việc',
      message: `${req.user.fullName} đã hủy giao công việc "${task.title}" của bạn`,
      email: null,
    });
  }
  res.json({
    success: true,
    message: 'Đã hủy giao việc',
    data: await loadTaskDto(task._id, req.user._id),
  });
});
