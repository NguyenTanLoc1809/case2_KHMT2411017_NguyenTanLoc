const AppError = require('../utils/AppError');

// validate(fn): fn(body) tra ve mang loi; neu co loi -> 400
const validate = (validatorFn) => (req, res, next) => {
  const errors = validatorFn(req.body || {});
  if (errors.length > 0) {
    return next(new AppError(errors[0], 400, errors));
  }
  next();
};

module.exports = validate;
