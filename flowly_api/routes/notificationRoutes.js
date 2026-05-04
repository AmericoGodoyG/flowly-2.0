const express = require('express');
const router = express.Router();
const auth = require('../middlewares/auth');
const notificationController = require('../controllers/notificationController');

router.use(auth);

// Rotas específicas ANTES das genéricas (importante!)
router.get('/count', notificationController.contarNaoLidas);
router.put('/mark-all-read', notificationController.marcarTodasComoLidas);
router.put('/:id/read', notificationController.marcarComoLida);
router.get('/', notificationController.listarNotificacoes);

module.exports = router;