const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const TaskActivity = require('../models/TaskActivity');

/**
 * Vai tro cua user tren 1 cong viec:
 *  owner    - nguoi tao: toan quyen (sua, xoa, quan ly chia se)
 *  editor   - duoc chia se quyen sua: xem + sua, KHONG xoa / quan ly quyen
 *  assignee - nguoi duoc giao: xem + cap nhat trang thai
 *  viewer   - chi xem
 * Neu vua la assignee vua co ban ghi share thi lay quyen cao hon.
 */
const ROLE_RANK = { viewer: 1, assignee: 2, editor: 3, owner: 4 };

function resolveRole(task, userId, share) {
  const uid = String(userId);
  if (String(task.createdBy && task.createdBy._id ? task.createdBy._id : task.createdBy) === uid) {
    return 'owner';
  }
  const roles = [];
  const isAssignee = (task.assigneeIds || []).some((a) => String(a && a._id ? a._id : a) === uid);
  if (isAssignee) roles.push('assignee');
  if (share) roles.push(share.permission); // viewer | editor
  if (roles.length === 0) return null;
  return roles.sort((a, b) => ROLE_RANK[b] - ROLE_RANK[a])[0];
}

const PERMISSIONS = {
  view: ['owner', 'editor', 'assignee', 'viewer'],
  status: ['owner', 'editor', 'assignee'],
  edit: ['owner', 'editor'],
  delete: ['owner'],
};

const can = (role, action) => !!role && PERMISSIONS[action].includes(role);

function permissionsOf(role) {
  return {
    canEdit: can(role, 'edit'),
    canUpdateStatus: can(role, 'status'),
    canDelete: can(role, 'delete'),
    canManageSharing: role === 'owner',
  };
}

async function getRoleForTask(task, userId) {
  const share = await TaskShare.findOne({ taskId: task._id, userId });
  return resolveRole(task, userId, share);
}

async function logActivity(taskId, userId, action, details = {}) {
  try {
    await TaskActivity.create({ taskId, userId, action, details });
  } catch (e) {
    console.error('Khong ghi duoc lich su hoat dong:', e.message);
  }
}

const POPULATE = [
  { path: 'createdBy', select: 'fullName email avatarUrl' },
  { path: 'assigneeIds', select: 'fullName email avatarUrl' },
  { path: 'primaryAssigneeId', select: 'fullName email avatarUrl' },
];

/** Gan myRole + permissions vao du lieu tra ve cho client. */
function serializeTask(task, role) {
  const obj = task.toJSON ? task.toJSON() : task;
  return { ...obj, myRole: role, permissions: permissionsOf(role) };
}

module.exports = {
  Task,
  resolveRole,
  can,
  permissionsOf,
  getRoleForTask,
  logActivity,
  serializeTask,
  POPULATE,
};
