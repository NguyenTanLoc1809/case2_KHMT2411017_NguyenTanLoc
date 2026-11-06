const notFound = (req, res, next) => {
  res.status(404).json({ success: false, message: 'Khong tim thay API' });
};

// Xu ly loi thong nhat, khong tiet lo thong tin nhay cam
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  let status = err.statusCode || 500;
  let message = err.isOperational ? err.message : 'Loi may chu, vui long thu lai sau';
  let errors = err.errors || undefined;

  if (err.code === 11000) {
    status = 409;
    message = 'Du lieu da ton tai';
  } else if (err.name === 'CastError') {
    status = 400;
    message = 'ID khong hop le';
  } else if (err.name === 'ValidationError') {
    status = 400;
    message = 'Du lieu khong hop le';
  } else if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'JSON khong hop le';
  }

  if (status >= 500) console.error(err);

  res.status(status).json({ success: false, message, ...(errors ? { errors } : {}) });
};

module.exports = { notFound, errorHandler };
