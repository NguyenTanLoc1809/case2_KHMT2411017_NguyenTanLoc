// Boc controller async de loi tu dong chuyen den errorMiddleware
module.exports = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
