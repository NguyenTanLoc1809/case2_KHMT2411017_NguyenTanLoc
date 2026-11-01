const router = require('express').Router({ mergeParams: true });
const validate = require('../middleware/validateMiddleware');
const { requireTaskAccess } = require('../middleware/permissionMiddleware');
const v = require('../validators/taskValidator');
const c = require('../controllers/taskShareController');

router.get('/', requireTaskAccess('view'), c.list);
router.post('/', requireTaskAccess('manage'), v.share, validate, c.share);
router.patch('/:shareId', requireTaskAccess('manage'), v.updateShare, validate, c.updatePermission);
router.delete('/:shareId', requireTaskAccess('manage'), v.shareIdParam, validate, c.revoke);

module.exports = router;
