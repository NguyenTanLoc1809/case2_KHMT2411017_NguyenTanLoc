const mongoose = require('mongoose');
const TaskShare = require('../models/TaskShare');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/ApiError');
const tpl = require('../utils/emailTemplates');
const { PERMISSION_LABEL } = require('../utils/helpers');
const { resolveUsers, logActivity, idEq } = require('../services/taskService');
const { dispatch } = require('../services/notificationService');

const populateShare = (q) => q.populate('userId', 'fullName email avatarUrl').populate('sharedBy', 'fullName email');

async function listShares(taskId) {
  return populateShare(TaskShare.find({ taskId }).sort({ createdAt: 1 }));
}

exports.list = asyncHandler(async (req, res) => {
  res.json({ success: true, data: await listShares(req.task._id) });
});

exports.share = asyncHandler(async (req, res) => {
  const task = req.task;
  const actor = req.user;
  const { userIds = [], emails = [], permission } = req.body;
  if (!userIds.length && !emails.length) throw new ApiError(400, 'Cần chọn ít nhất một người để chia sẻ');

  const { users, notFoundEmails } = await resolveUsers({ userIds, emails });
  if (!users.length) throw new ApiError(404, 'Không tìm thấy người dùng phù hợp');

  const result = { added: [], updated: [], unchanged: [], skipped: [] };

  for (const u of users) {
    if (idEq(task.createdBy, u._id)) {
      result.skipped.push(u.email); // không chia sẻ cho chính người tạo
      continue;
    }
    // upsert nguyên tử: trả về bản ghi cũ (nếu có) để biết là thêm mới hay đổi quyền
    const before = await TaskShare.findOneAndUpdate(
      { taskId: task._id, userId: u._id },
      { $set: { permission }, $setOnInsert: { sharedBy: actor._id } },
      { upsert: true, new: false }
    );

    if (!before) {
      result.added.push(u.email);
      await logActivity(task._id, actor._id, 'shared', { user: u.fullName, permission });
      await dispatch({
        task, actor, recipients: [u], type: 'task_shared',
        title: 'Công việc được chia sẻ với bạn',
        message: `${actor.fullName} đã chia sẻ "${task.title}" với bạn (quyền: ${PERMISSION_LABEL[permission]})`,
        email: (user) => tpl.taskShared({ user, task, actor, permission }),
      });
    } else if (before.permission !== permission) {
      result.updated.push(u.email);
      await logActivity(task._id, actor._id, 'share_updated', { user: u.fullName, permission });
      await dispatch({
        task, actor, recipients: [u], type: 'share_permission_changed',
        title: 'Quyền truy cập thay đổi',
        message: `Quyền của bạn trên "${task.title}" đã đổi thành: ${PERMISSION_LABEL[permission]}`,
        email: null,
      });
    } else {
      result.unchanged.push(u.email);
    }
  }

  res.status(201).json({
    success: true,
    message: 'Đã xử lý chia sẻ',
    data: await listShares(task._id),
    result,
    notFoundEmails,
  });
});

async function findShare(req) {
  if (!mongoose.isObjectIdOrHexString(req.params.shareId)) throw new ApiError(400, 'Mã chia sẻ không hợp lệ');
  const share = await TaskShare.findOne({ _id: req.params.shareId, taskId: req.task._id });
  if (!share) throw new ApiError(404, 'Không tìm thấy bản ghi chia sẻ');
  return share;
}

exports.updatePermission = asyncHandler(async (req, res) => {
  const share = await findShare(req);
  const { permission } = req.body;
  if (share.permission !== permission) {
    share.permission = permission;
    await share.save();
    await logActivity(req.task._id, req.user._id, 'share_updated', { userId: String(share.userId), permission });
    await dispatch({
      task: req.task, actor: req.user, recipients: [{ _id: share.userId, email: '', fullName: '' }],
      type: 'share_permission_changed',
      title: 'Quyền truy cập thay đổi',
      message: `Quyền của bạn trên "${req.task.title}" đã đổi thành: ${PERMISSION_LABEL[permission]}`,
      email: null,
    });
  }
  res.json({ success: true, message: 'Đã cập nhật quyền', data: await listShares(req.task._id) });
});

exports.revoke = asyncHandler(async (req, res) => {
  const share = await findShare(req);
  await share.deleteOne();
  await logActivity(req.task._id, req.user._id, 'share_revoked', { userId: String(share.userId) });
  await dispatch({
    task: req.task, actor: req.user, recipients: [{ _id: share.userId, email: '', fullName: '' }],
    type: 'share_revoked',
    title: 'Quyền truy cập bị thu hồi',
    message: `${req.user.fullName} đã thu hồi quyền truy cập của bạn vào "${req.task.title}"`,
    email: null,
  });
  res.json({ success: true, message: 'Đã thu hồi quyền chia sẻ', data: await listShares(req.task._id) });
});
