const jwt = require('jsonwebtoken');
const User = require('../models/User');
const AppError = require('../utils/AppError');
const asyncHandler = require('../utils/asyncHandler');

// Xac thuc token JWT o backend cho moi API rieng tu
const protect = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    throw new AppError('Vui long dang nhap', 401);
  }

  let payload;
  try {
    payload = jwt.verify(token, process.env.JWT_SECRET);
  } catch (e) {
    throw new AppError('Phien dang nhap khong hop le hoac da het han', 401);
  }

  const user = await User.findById(payload.id);
  if (!user) throw new AppError('Tai khoan khong ton tai', 401);

  req.user = user;
  next();
});

module.exports = { protect };
