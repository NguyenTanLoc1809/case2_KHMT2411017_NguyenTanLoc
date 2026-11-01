const jwt = require('jsonwebtoken');
const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

module.exports = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    throw new ApiError(401, 'Bạn chưa đăng nhập');
  }
  const payload = jwt.verify(token, process.env.JWT_SECRET); // lỗi -> errorMiddleware (401)
  const user = await User.findById(payload.sub);
  if (!user) throw new ApiError(401, 'Tài khoản không tồn tại');
  req.user = user;
  next();
});
