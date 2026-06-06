const express = require('express');
const router = express.Router();
const storageController = require('../controllers/storageController');

router.get('/files/:encodedPath', storageController.downloadFile);

module.exports = router;
