const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const AppError = require('../utils/AppError');
const asyncHandler = require('../utils/asyncHandler');

const signToken = (userId) =>
  jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

// POST /api/auth/register
exports.register = asyncHandler(async (req, res) => {
  const fullName = req.body.fullName.trim();
  const email = req.body.email.trim().toLowerCase();

  const existed = await User.findOne({ email });
  if (existed) throw new AppError('Email da duoc su dung', 409);

  const passwordHash = await bcrypt.hash(req.body.password, 10);
  const user = await User.create({ fullName, email, passwordHash });

  res.status(201).json({
    success: true,
    message: 'Dang ky thanh cong',
    data: { token: signToken(user._id), user },
  });
});

// POST /api/auth/login
exports.login = asyncHandler(async (req, res) => {
  const email = req.body.email.trim().toLowerCase();
  const user = await User.findOne({ email }).select('+passwordHash');

  // Cung 1 thong bao cho ca "sai email" va "sai mat khau"
  const ok = user && (await bcrypt.compare(req.body.password, user.passwordHash));
  if (!ok) throw new AppError('Email hoac mat khau khong dung', 401);

  res.json({
    success: true,
    message: 'Dang nhap thanh cong',
    data: { token: signToken(user._id), user },
  });
});

// GET /api/auth/me
exports.getMe = asyncHandler(async (req, res) => {
  res.json({ success: true, data: { user: req.user } });
});

// PUT /api/auth/me
exports.updateMe = asyncHandler(async (req, res) => {
  const { fullName, avatarUrl } = req.body;
  if (fullName !== undefined) req.user.fullName = fullName.trim();
  if (avatarUrl !== undefined) req.user.avatarUrl = avatarUrl.trim();
  await req.user.save();

  res.json({ success: true, message: 'Cap nhat thong tin thanh cong', data: { user: req.user } });
});

// PUT /api/auth/change-password
exports.changePassword = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id).select('+passwordHash');
  const ok = await bcrypt.compare(req.body.currentPassword, user.passwordHash);
  if (!ok) throw new AppError('Mat khau hien tai khong dung', 400);

  user.passwordHash = await bcrypt.hash(req.body.newPassword, 10);
  await user.save();

  res.json({ success: true, message: 'Doi mat khau thanh cong' });
});
