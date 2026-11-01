const mongoose = require('mongoose');
const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { escapeRegex } = require('../utils/helpers');

exports.search = asyncHandler(async (req, res) => {
  const q = String(req.query.q || '').trim().slice(0, 100);
  if (!q) return res.json({ success: true, data: [] });
  const rx = new RegExp(escapeRegex(q), 'i');
  const users = await User.find({ $or: [{ fullName: rx }, { email: rx }] })
    .select('fullName email avatarUrl')
    .sort({ fullName: 1 })
    .limit(10);
  res.json({ success: true, data: users });
});

exports.getById = asyncHandler(async (req, res) => {
  if (!mongoose.isObjectIdOrHexString(req.params.id)) throw new ApiError(400, 'Mã người dùng không hợp lệ');
  const user = await User.findById(req.params.id).select('fullName email avatarUrl');
  if (!user) throw new ApiError(404, 'Không tìm thấy người dùng');
  res.json({ success: true, data: user });
});
