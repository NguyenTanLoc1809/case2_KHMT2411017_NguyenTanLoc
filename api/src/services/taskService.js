const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const TaskActivity = require('../models/TaskActivity');
const User = require('../models/User');

const USER_FIELDS = 'fullName email avatarUrl';
const POPULATE = [
  { path: 'createdBy', select: USER_FIELDS },
  { path: 'assigneeIds', select: USER_FIELDS },
  { path: 'primaryAssigneeId', select: USER_FIELDS },
];

const refId = (x) => (x && x._id ? x._id : x);
const idEq = (a, b) => !!a && !!b && a.toString() === b.toString();

/**
 * Tính quyền của một người dùng trên công việc (đồng bộ).
 * Nếu một người vừa được giao vừa được chia sẻ thì lấy quyền cao nhất:
 *  - owner (người tạo): xem, sửa, xóa, quản lý giao việc/chia sẻ
 *  - assignee (người được giao) và editor: xem + sửa (kể cả đổi trạng thái)
 *  - viewer: chỉ xem
 */
function computeAccess(task, userId, sharePermission) {
  const isOwner = idEq(refId(task.createdBy), userId);
  const isAssignee = task.assigneeIds.some((a) => idEq(refId(a), userId));
  const canView = isOwner || isAssignee || !!sharePermission;
  const canEdit = isOwner || isAssignee || sharePermission === 'editor';
  let role = null;
  if (isOwner) role = 'owner';
  else if (isAssignee) role = 'assignee';
  else if (sharePermission) role = sharePermission;
  return { role, canView, canEdit, canDelete: isOwner, canManage: isOwner };
}

async function getAccess(task, userId) {
  const share = await TaskShare.findOne({ taskId: task._id, userId });
  return computeAccess(task, userId, share ? share.permission : null);
}

const pubUser = (u) =>
  u && u._id ? { _id: u._id, fullName: u.fullName, email: u.email, avatarUrl: u.avatarUrl || '' } : null;

function toTaskDto(task, userId, sharePermission) {
  const access = computeAccess(task, userId, sharePermission);
  return {
    _id: task._id,
    title: task.title,
    description: task.description,
    createdBy: pubUser(task.createdBy),
    assignees: task.assigneeIds.map(pubUser).filter(Boolean),
    primaryAssignee: pubUser(task.primaryAssigneeId),
    startDate: task.startDate,
    dueDate: task.dueDate,
    priority: task.priority,
    status: task.status,
    completedAt: task.completedAt,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    myRole: access.role,
    permissions: { canEdit: access.canEdit, canDelete: access.canDelete, canManage: access.canManage },
  };
}

async function serializeTasks(tasks, userId) {
  const shares = await TaskShare.find({ userId, taskId: { $in: tasks.map((t) => t._id) } });
  const map = new Map(shares.map((s) => [s.taskId.toString(), s.permission]));
  return tasks.map((t) => toTaskDto(t, userId, map.get(t._id.toString()) || null));
}

async function loadTaskDto(taskId, userId) {
  const task = await Task.findById(taskId).populate(POPULATE);
  const share = await TaskShare.findOne({ taskId, userId });
  return toTaskDto(task, userId, share ? share.permission : null);
}

/** Bộ lọc các công việc mà người dùng có quyền truy cập, theo phạm vi (scope). */
async function buildAccessFilter(userId, scope) {
  const sharedIds = await TaskShare.find({ userId }).distinct('taskId');
  const created = { createdBy: userId };
  const assigned = { assigneeIds: userId };
  const shared = { _id: { $in: sharedIds } };
  if (scope === 'created') return created;
  if (scope === 'assigned') return assigned;
  if (scope === 'shared') return shared;
  return { $or: [created, assigned, shared] };
}

/** Người tạo + người được giao + người được chia sẻ (document User đầy đủ email, tên). */
async function getParticipants(task) {
  const shareUserIds = await TaskShare.find({ taskId: task._id }).distinct('userId');
  const ids = new Set(
    [refId(task.createdBy), ...task.assigneeIds.map(refId), ...shareUserIds].map((x) => x.toString())
  );
  return User.find({ _id: { $in: [...ids] } }).select('fullName email');
}

/** Tìm người dùng theo danh sách id và/hoặc email. */
async function resolveUsers({ userIds = [], emails = [] }) {
  const users = await User.find({
    $or: [{ _id: { $in: userIds } }, { email: { $in: emails } }],
  }).select(USER_FIELDS);
  const found = new Set(users.map((u) => u.email));
  const notFoundEmails = emails.filter((e) => !found.has(e));
  return { users, notFoundEmails };
}

async function logActivity(taskId, userId, action, details = {}) {
  try {
    await TaskActivity.create({ taskId, userId, action, details });
  } catch (err) {
    console.error('[activity] Không ghi được lịch sử:', err.message);
  }
}

module.exports = {
  POPULATE,
  refId,
  idEq,
  computeAccess,
  getAccess,
  toTaskDto,
  serializeTasks,
  loadTaskDto,
  buildAccessFilter,
  getParticipants,
  resolveUsers,
  logActivity,
};
