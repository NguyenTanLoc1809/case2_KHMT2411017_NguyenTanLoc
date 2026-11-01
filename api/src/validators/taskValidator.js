const { body, query, param } = require('express-validator');
const { PRIORITIES, STATUSES } = require('../models/Task');

const dateRange = (value, { req }) => {
  if (req.body.startDate && new Date(value) < new Date(req.body.startDate)) {
    throw new Error('Hạn hoàn thành phải sau hoặc bằng ngày bắt đầu');
  }
  return true;
};

exports.createTask = [
  body('title').isString().trim().notEmpty().withMessage('Tên công việc không được để trống')
    .isLength({ max: 200 }).withMessage('Tên công việc tối đa 200 ký tự'),
  body('description').optional({ values: 'null' }).isString().withMessage('Mô tả không hợp lệ')
    .isLength({ max: 2000 }).withMessage('Mô tả tối đa 2000 ký tự'),
  body('startDate').optional({ values: 'falsy' }).isISO8601().withMessage('Ngày bắt đầu không hợp lệ'),
  body('dueDate').notEmpty().withMessage('Hạn hoàn thành là bắt buộc').bail()
    .isISO8601().withMessage('Hạn hoàn thành không hợp lệ').bail()
    .custom(dateRange),
  body('priority').optional().isIn(PRIORITIES).withMessage('Mức độ ưu tiên không hợp lệ'),
  body('status').optional().isIn(STATUSES).withMessage('Trạng thái không hợp lệ'),
];

exports.updateTask = [
  body('title').optional().isString().trim().notEmpty().withMessage('Tên công việc không được để trống')
    .isLength({ max: 200 }).withMessage('Tên công việc tối đa 200 ký tự'),
  body('description').optional({ values: 'null' }).isString().withMessage('Mô tả không hợp lệ')
    .isLength({ max: 2000 }).withMessage('Mô tả tối đa 2000 ký tự'),
  body('startDate').optional({ values: 'falsy' }).isISO8601().withMessage('Ngày bắt đầu không hợp lệ'),
  body('dueDate').optional().isISO8601().withMessage('Hạn hoàn thành không hợp lệ').bail().custom(dateRange),
  body('priority').optional().isIn(PRIORITIES).withMessage('Mức độ ưu tiên không hợp lệ'),
  body('status').optional().isIn(STATUSES).withMessage('Trạng thái không hợp lệ'),
];

exports.updateStatus = [body('status').isIn(STATUSES).withMessage('Trạng thái không hợp lệ')];

exports.listQuery = [
  query('scope').optional({ values: 'falsy' }).isIn(['created', 'assigned', 'shared']).withMessage('scope không hợp lệ'),
  query('status').optional({ values: 'falsy' }).isIn(STATUSES).withMessage('status không hợp lệ'),
  query('priority').optional({ values: 'falsy' }).isIn(PRIORITIES).withMessage('priority không hợp lệ'),
  query('assigneeId').optional({ values: 'falsy' }).isMongoId().withMessage('assigneeId không hợp lệ'),
  query('sortBy').optional({ values: 'falsy' }).isIn(['dueDate', 'priority', 'createdAt']).withMessage('sortBy không hợp lệ'),
  query('order').optional({ values: 'falsy' }).isIn(['asc', 'desc']).withMessage('order không hợp lệ'),
];

// ----- Giao việc & chia sẻ -----
const emailsAndIds = () => [
  body('userIds').optional().isArray({ max: 50 }).withMessage('userIds phải là mảng'),
  body('userIds.*').isMongoId().withMessage('Mã người dùng không hợp lệ'),
  body('emails').optional().isArray({ max: 50 }).withMessage('emails phải là mảng'),
  body('emails.*').isString().customSanitizer((v) => String(v).trim().toLowerCase())
    .isEmail().withMessage('Email không hợp lệ'),
];

exports.assign = [
  ...emailsAndIds(),
  body('primaryAssigneeId').optional({ values: 'falsy' }).isMongoId().withMessage('Người phụ trách chính không hợp lệ'),
];

exports.updateAssignee = [
  param('userId').isMongoId().withMessage('Mã người dùng không hợp lệ'),
  body('isPrimary').isBoolean().withMessage('isPrimary phải là true/false'),
];

exports.userIdParam = [param('userId').isMongoId().withMessage('Mã người dùng không hợp lệ')];

exports.share = [
  ...emailsAndIds(),
  body('permission').isIn(['viewer', 'editor']).withMessage('Quyền phải là viewer hoặc editor'),
];

exports.updateShare = [
  param('shareId').isMongoId().withMessage('Mã chia sẻ không hợp lệ'),
  body('permission').isIn(['viewer', 'editor']).withMessage('Quyền phải là viewer hoặc editor'),
];

exports.shareIdParam = [param('shareId').isMongoId().withMessage('Mã chia sẻ không hợp lệ')];
