const mongoose = require('mongoose');
const EmailLog = require('../models/EmailLog');
const Task = require('../models/Task');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/ApiError');
const { retryEmail } = require('../services/emailService');

// GET /tasks/:id/email-logs  (chỉ người tạo công việc)
exports.listByTask = asyncHandler(async (req, res) => {
  const logs = await EmailLog.find({ taskId: req.task._id }).sort({ createdAt: -1 }).limit(100);
  res.json({ success: true, data: logs });
});

// POST /email-logs/:id/retry  (chỉ người tạo công việc liên quan, chỉ email failed và chưa vượt số lần thử)
exports.retry = asyncHandler(async (req, res) => {
  if (!mongoose.isObjectIdOrHexString(req.params.id)) throw new ApiError(400, 'Mã email không hợp lệ');
  const log = await EmailLog.findById(req.params.id);
  if (!log) throw new ApiError(404, 'Không tìm thấy lịch sử email');

  const task = log.taskId ? await Task.findById(log.taskId) : null;
  if (!task || String(task.createdBy) !== String(req.user._id)) {
    throw new ApiError(403, 'Bạn không có quyền gửi lại email này');
  }

  const ok = await retryEmail(log._id);
  if (!ok) throw new ApiError(400, 'Email này không thể gửi lại (đã gửi thành công hoặc vượt quá số lần thử)');

  res.status(202).json({
    success: true,
    message: 'Đã đưa email vào hàng đợi gửi lại',
    data: await EmailLog.findById(log._id),
  });
});
