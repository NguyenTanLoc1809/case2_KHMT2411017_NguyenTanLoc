const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/ApiError');

exports.list = asyncHandler(async (req, res) => {
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 30, 1), 100);
  const filter = { userId: req.user._id };
  if (req.query.unreadOnly === 'true') filter.isRead = false;

  const [data, total] = await Promise.all([
    Notification.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit),
    Notification.countDocuments(filter),
  ]);
  res.json({ success: true, data, pagination: { page, limit, total } });
});

exports.unreadCount = asyncHandler(async (req, res) => {
  const count = await Notification.countDocuments({ userId: req.user._id, isRead: false });
  res.json({ success: true, data: { count } });
});

exports.markRead = asyncHandler(async (req, res) => {
  if (!mongoose.isObjectIdOrHexString(req.params.id)) throw new ApiError(400, 'Mã thông báo không hợp lệ');
  const n = await Notification.findOneAndUpdate(
    { _id: req.params.id, userId: req.user._id },
    { isRead: true },
    { new: true }
  );
  if (!n) throw new ApiError(404, 'Không tìm thấy thông báo');
  res.json({ success: true, data: n });
});

exports.markAllRead = asyncHandler(async (req, res) => {
  const r = await Notification.updateMany({ userId: req.user._id, isRead: false }, { isRead: true });
  res.json({ success: true, message: 'Đã đánh dấu tất cả là đã đọc', data: { modified: r.modifiedCount } });
});
