const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const c = require('../controllers/statisticsController');

router.use(auth);
router.get('/tasks', c.tasks);
router.get('/assignments', c.assignments);
router.get('/deadlines', c.deadlines);

module.exports = router;
