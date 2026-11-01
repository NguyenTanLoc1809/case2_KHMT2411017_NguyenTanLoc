const { body } = require('express-validator');

const emailRule = () =>
  body('email')
    .isString().withMessage('Email không hợp lệ')
    .bail()
    .customSanitizer((v) => String(v).trim().toLowerCase())
    .isEmail().withMessage('Email không hợp lệ');

const passwordRule = (field = 'password', label = 'Mật khẩu') =>
  body(field)
    .isString().withMessage(`${label} không hợp lệ`)
    .bail()
    .isLength({ min: 6, max: 72 }).withMessage(`${label} phải từ 6 đến 72 ký tự`);

exports.register = [
  body('fullName').isString().trim().notEmpty().withMessage('Họ tên không được để trống')
    .isLength({ max: 100 }).withMessage('Họ tên tối đa 100 ký tự'),
  emailRule(),
  passwordRule(),
];

exports.login = [
  emailRule(),
  body('password').isString().notEmpty().withMessage('Vui lòng nhập mật khẩu'),
];

exports.updateMe = [
  body('fullName').optional().isString().trim().notEmpty().withMessage('Họ tên không được để trống')
    .isLength({ max: 100 }).withMessage('Họ tên tối đa 100 ký tự'),
  body('avatarUrl').optional({ values: 'falsy' }).isURL().withMessage('Đường dẫn ảnh không hợp lệ'),
];

exports.changePassword = [
  body('currentPassword').isString().notEmpty().withMessage('Vui lòng nhập mật khẩu hiện tại'),
  passwordRule('newPassword', 'Mật khẩu mới'),
];
