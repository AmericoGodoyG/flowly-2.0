const { HTTP_STATUS, ERROR_MESSAGES } = require('../config/constants');

/**
 * Middleware centralizado para tratamento de erros
 */
const errorHandler = (err, req, res, next) => {
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
