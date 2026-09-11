const { Router } = require('express');
const auth = require('../controllers/auth.controller');
const requireAuth = require('../middlewares/auth.middleware');

const router = Router();

router.post('/register', auth.register);
router.post('/login', auth.login);
router.post('/forgot-password', auth.forgotPassword);
router.post('/reset-password', auth.resetPassword);
router.get('/me', requireAuth, auth.me);

module.exports = router;
