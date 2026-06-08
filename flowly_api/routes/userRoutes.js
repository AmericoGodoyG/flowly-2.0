const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth');
const upload = require('../middlewares/upload');
const moderateUpload = require('../middlewares/moderateUpload');
const userController = require('../controllers/userController');

router.use(auth);

router.get('/search', userController.searchUsers);
router.get('/', userController.listarUsers);
router.get('/me', userController.me);
router.put('/me', upload.single('fotoPerfil'), moderateUpload('profile_image'), userController.atualizarPerfil);
router.put('/me/password', userController.atualizarSenha);

module.exports = router;
