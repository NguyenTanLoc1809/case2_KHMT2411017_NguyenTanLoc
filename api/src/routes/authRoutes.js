const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateMiddleware');
const v = require('../validators/authValidator');
const c = require('../controllers/authController');

router.post('/register', v.register, validate, c.register);
router.post('/login', v.login, validate, c.login);
router.get('/me', auth, c.getMe);
router.put('/me', auth, v.updateMe, validate, c.updateMe);
router.put('/change-password', auth, v.changePassword, validate, c.changePassword);

module.exports = router;
