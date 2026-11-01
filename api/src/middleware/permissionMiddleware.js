const mongoose = require('mongoose');
const Task = require('../models/Task');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { getAccess } = require('../services/taskService');

const FLAG = { view: 'canView', edit: 'canEdit', delete: 'canDelete', manage: 'canManage' };
const DENY_MESSAGE = {
  edit: 'Bạn chỉ có quyền xem công việc này',
  delete: 'Chỉ người tạo mới được xóa công việc',
  manage: 'Chỉ người tạo mới được quản lý giao việc và chia sẻ',
};

/**
 * Nạp công việc theo :id và kiểm tra quyền của người dùng hiện tại.
 * level: view | edit | delete | manage
 * Kết quả: req.task (document gốc, chưa populate) và req.access.
 */
exports.requireTaskAccess = (level = 'view') =>
  asyncHandler(async (req, res, next) => {
    const { id } = req.params;
    if (!mongoose.isObjectIdOrHexString(id)) throw new ApiError(400, 'Mã công việc không hợp lệ');

    const task = await Task.findById(id);
    if (!task) throw new ApiError(404, 'Không tìm thấy công việc');

    const access = await getAccess(task, req.user._id);
    // Không có quyền xem -> trả 404 để không lộ sự tồn tại của công việc
    if (!access.canView) throw new ApiError(404, 'Không tìm thấy công việc');
    if (!access[FLAG[level]]) throw new ApiError(403, DENY_MESSAGE[level]);

    req.task = task;
    req.access = access;
    next();
  });
