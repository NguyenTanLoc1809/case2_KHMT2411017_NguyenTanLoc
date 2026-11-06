const router = require('express').Router();
const users = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);
router.get('/search', users.searchUsers);
router.get('/:id', users.getUserById);

module.exports = router;
