const mongoose = require('mongoose');
const User = require('../models/User');
const AppError = require('../utils/AppError');
const asyncHandler = require('../utils/asyncHandler');

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const publicFields = 'fullName email avatarUrl';

// GET /api/users/search?q=
exports.searchUsers = asyncHandler(async (req, res) => {
  const q = (req.query.q || '').toString().trim();
  if (q.length < 2) {
    return res.json({ success: true, data: { users: [] } });
  }
  const regex = new RegExp(escapeRegex(q), 'i');
  const users = await User.find({
    _id: { $ne: req.user._id },
    $or: [{ fullName: regex }, { email: regex }],
  })
    .select(publicFields)
    .limit(20);

  res.json({ success: true, data: { users } });
});

// GET /api/users/:id
exports.getUserById = asyncHandler(async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) throw new AppError('ID khong hop le', 400);
  const user = await User.findById(req.params.id).select(publicFields);
  if (!user) throw new AppError('Khong tim thay nguoi dung', 404);
  res.json({ success: true, data: { user } });
});
