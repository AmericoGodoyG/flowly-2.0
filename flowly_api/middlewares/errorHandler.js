const { HTTP_STATUS, ERROR_MESSAGES } = require('../config/constants');
const multer = require('multer');

/**
 * Middleware centralizado para tratamento de erros
 */
const errorHandler = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    const statusCode = err.code === 'LIMIT_FILE_SIZE'
      ? HTTP_STATUS.PAYLOAD_TOO_LARGE || 413
      : HTTP_STATUS.BAD_REQUEST || 400;

    return res.status(statusCode).json({
      success: false,
      error: err.code === 'LIMIT_FILE_SIZE'
        ? 'Arquivo excede o limite de 10 MB.'
        : err.message,
    });
  }

  if (err.message && err.message.includes('Tipo de arquivo nao permitido')) {
    return res.status(HTTP_STATUS.BAD_REQUEST || 400).json({
      success: false,
      error: err.message,
    });
  }

  const statusCode = err.status || HTTP_STATUS.INTERNAL_SERVER_ERROR;
  const message = err.message || ERROR_MESSAGES.INTERNAL_ERROR;

  console.error(`[ERROR] ${statusCode} - ${message}`, err);

  res.status(statusCode).json({
    success: false,
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

module.exports = errorHandler;
