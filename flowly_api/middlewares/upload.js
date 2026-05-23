const multer = require('multer');
const path = require('path');

const allowedMimeTypes = [
      'image/jpeg',
      'image/png',
      'application/pdf'
    ];

const allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.csv', '.txt', '.zip'];

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  const isMimeTypeAllowed = allowedMimeTypes.includes(file.mimetype);
  const isExtensionAllowed = allowedExtensions.includes(ext);

  if (isMimeTypeAllowed && isExtensionAllowed) {
    cb(null, true);
  } else {
    cb(new Error('Tipo de arquivo não permitido! Tente imagens ou documentos.'), false);
  }
};

// Multer em memoria
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024 // Limite de 10 MB
  },
  fileFilter: fileFilter
});

module.exports = upload;
