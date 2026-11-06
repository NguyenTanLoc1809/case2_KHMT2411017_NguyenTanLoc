const router = require('express').Router();
const tasks = require('../controllers/taskController');
const { protect } = require('../middleware/authMiddleware');
const { requireTaskPermission } = require('../middleware/permissionMiddleware');
const validate = require('../middleware/validateMiddleware');
const v = require('../validators/taskValidator');

router.use(protect);

router.get('/', tasks.listTasks);
router.post('/', validate(v.validateCreateTask), tasks.createTask);

router.get('/:id', requireTaskPermission('view'), tasks.getTask);
router.put('/:id', validate(v.validateUpdateTask), requireTaskPermission('edit'), tasks.updateTask);
router.delete('/:id', requireTaskPermission('delete'), tasks.deleteTask);
router.patch('/:id/status', validate(v.validateStatus), requireTaskPermission('status'), tasks.updateStatus);
router.get('/:id/activities', requireTaskPermission('view'), tasks.getActivities);

module.exports = router;
