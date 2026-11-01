const ApiError = require('../utils/ApiError');

exports.notFound = (req, res, next) => {
  next(new ApiError(404, `Không tìm thấy đường dẫn ${req.method} ${req.originalUrl}`));
};

// eslint-disable-next-line no-unused-vars
exports.errorHandler = (err, req, res, next) => {
  let status = err.statusCode || 500;
  let message = err.message;
  let errors = err.errors;

  if (err.name === 'ValidationError' && !err.isOperational) {
    status = 400;
    message = 'Dữ liệu không hợp lệ';
    errors = Object.values(err.errors).map((e) => ({ field: e.path, message: e.message }));
  } else if (err.name === 'CastError') {
    status = 400;
    message = 'Giá trị không hợp lệ';
  } else if (err.code === 11000) {
    status = 409;
    message = 'Dữ liệu đã tồn tại';
  } else if (err.name === 'TokenExpiredError') {
    status = 401;
    message = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';
  } else if (err.name === 'JsonWebTokenError') {
    status = 401;
    message = 'Token không hợp lệ';
  } else if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'JSON gửi lên không hợp lệ';
  }

  if (status >= 500) {
    console.error('[ERROR]', err);
    message = 'Lỗi máy chủ nội bộ'; // không tiết lộ chi tiết lỗi cho client
    errors = undefined;
  }

  res.status(status).json({ success: false, message, ...(errors ? { errors } : {}) });
};
