const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const c = require('../controllers/userController');

router.use(auth);
router.get('/search', c.search);
router.get('/:id', c.getById);

module.exports = router;
