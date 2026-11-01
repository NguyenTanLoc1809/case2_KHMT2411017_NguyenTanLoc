const router = require('express').Router({ mergeParams: true });
const validate = require('../middleware/validateMiddleware');
const { requireTaskAccess } = require('../middleware/permissionMiddleware');
const v = require('../validators/taskValidator');
const c = require('../controllers/assignmentController');

// (authMiddleware đã được áp dụng ở taskRoutes)
router.get('/', requireTaskAccess('view'), c.list);
router.post('/', requireTaskAccess('manage'), v.assign, validate, c.assign);
router.patch('/:userId', requireTaskAccess('manage'), v.updateAssignee, validate, c.setPrimary);
router.delete('/:userId', requireTaskAccess('manage'), v.userIdParam, validate, c.unassign);

module.exports = router;
