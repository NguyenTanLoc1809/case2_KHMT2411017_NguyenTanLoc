const router = require('express').Router();
const auth = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');
const validate = require('../middleware/validateMiddleware');
const v = require('../validators/authValidator');

router.post('/register', validate(v.validateRegister), auth.register);
router.post('/login', validate(v.validateLogin), auth.login);
router.get('/me', protect, auth.getMe);
router.put('/me', protect, validate(v.validateUpdateProfile), auth.updateMe);
router.put('/change-password', protect, validate(v.validateChangePassword), auth.changePassword);

module.exports = router;
