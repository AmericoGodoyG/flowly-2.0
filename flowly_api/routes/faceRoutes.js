const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth');
const faceController = require('../controllers/faceController');

router.get('/health', faceController.health);

router.post('/enroll', faceController.enrollWithSession);
router.post('/verify', faceController.verifyWithSession);
router.post('/skip-enrollment', faceController.skipEnrollment);

router.get('/status', auth, faceController.getStatus);
router.post('/enroll-profile', auth, faceController.enrollFromProfile);

module.exports = router;
