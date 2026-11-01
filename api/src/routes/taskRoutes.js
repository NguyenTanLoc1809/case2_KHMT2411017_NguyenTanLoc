const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateMiddleware');
const { requireTaskAccess } = require('../middleware/permissionMiddleware');
const v = require('../validators/taskValidator');
const c = require('../controllers/taskController');
const emailLogController = require('../controllers/emailLogController');

router.use(auth);

router.get('/', v.listQuery, validate, c.listTasks);
router.post('/', v.createTask, validate, c.createTask);

router.get('/:id', requireTaskAccess('view'), c.getTask);
router.put('/:id', requireTaskAccess('edit'), v.updateTask, validate, c.updateTask);
router.delete('/:id', requireTaskAccess('delete'), c.deleteTask);

router.patch('/:id/status', requireTaskAccess('edit'), v.updateStatus, validate, c.updateStatus);
router.get('/:id/activities', requireTaskAccess('view'), c.getActivities);
router.get('/:id/email-logs', requireTaskAccess('manage'), emailLogController.listByTask);

router.use('/:id/assignees', require('./assignmentRoutes')); // [C]
router.use('/:id/shares', require('./taskShareRoutes')); // [C]

module.exports = router;
