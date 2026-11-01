const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

const signToken = (id) =>
  jwt.sign({ sub: id.toString() }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

exports.register = asyncHandler(async (req, res) => {
  const { fullName, email, password } = req.body;
  if (await User.exists({ email })) throw new ApiError(409, 'Email đã được sử dụng');

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await User.create({ fullName, email, passwordHash });
  res.status(201).json({
    success: true,
    message: 'Đăng ký thành công',
    data: { token: signToken(user._id), user },
  });
});

exports.login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email }).select('+passwordHash');
  const ok = user && (await bcrypt.compare(password, user.passwordHash));
  if (!ok) throw new ApiError(401, 'Email hoặc mật khẩu không đúng'); // không tiết lộ email có tồn tại hay không
  res.json({
    success: true,
    message: 'Đăng nhập thành công',
    data: { token: signToken(user._id), user },
  });
});

exports.getMe = asyncHandler(async (req, res) => {
  res.json({ success: true, data: req.user });
});

exports.updateMe = asyncHandler(async (req, res) => {
  const { fullName, avatarUrl } = req.body;
  if (fullName !== undefined) req.user.fullName = fullName;
  if (avatarUrl !== undefined) req.user.avatarUrl = avatarUrl || '';
  await req.user.save();
  res.json({ success: true, message: 'Cập nhật thông tin thành công', data: req.user });
});

exports.changePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const user = await User.findById(req.user._id).select('+passwordHash');
  if (!(await bcrypt.compare(currentPassword, user.passwordHash))) {
    throw new ApiError(400, 'Mật khẩu hiện tại không đúng');
  }
  if (currentPassword === newPassword) {
    throw new ApiError(400, 'Mật khẩu mới phải khác mật khẩu hiện tại');
  }
  user.passwordHash = await bcrypt.hash(newPassword, 10);
  await user.save();
  res.json({ success: true, message: 'Đổi mật khẩu thành công' });
});
