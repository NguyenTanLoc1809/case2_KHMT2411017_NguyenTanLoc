const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const c = require('../controllers/emailLogController');

router.use(auth);
router.post('/:id/retry', c.retry);

module.exports = router;
