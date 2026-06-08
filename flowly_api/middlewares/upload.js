const multer = require('multer');
const path = require('path');

const allowedMimeTypes = [
  'image/jpeg',
  'image/png',
  'application/pdf',
];

const allowedExtensionsByMime = {
  'image/jpeg': ['.jpg', '.jpeg'],
  'image/png': ['.png'],
  'application/pdf': ['.pdf'],
};

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname || '').toLowerCase();
  const isMimeTypeAllowed = allowedMimeTypes.includes(file.mimetype);
  const isExtensionAllowed = allowedExtensionsByMime[file.mimetype]?.includes(ext);

  if (isMimeTypeAllowed && isExtensionAllowed) {
    cb(null, true);
    return;
  }

  cb(new Error('Tipo de arquivo nao permitido! Use PNG, JPG ou PDF.'), false);
};

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
  fileFilter,
});

module.exports = upload;
