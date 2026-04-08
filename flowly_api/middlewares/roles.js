const { HTTP_STATUS, ERROR_MESSAGES, USER_TYPES } = require('../config/constants');

/**
 * Middlewares para verificação de roles/permissões
 */

const isAdmin = (req, res, next) => {
  if (req.user.tipo !== USER_TYPES.ADMIN) {
    return res.status(HTTP_STATUS.FORBIDDEN).json({
      success: false,
      error: ERROR_MESSAGES.ADMIN_ONLY,
    });
  }
  next();
};

const isUser = (req, res, next) => {
  if (req.user.tipo !== USER_TYPES.USER) {
    return res.status(HTTP_STATUS.FORBIDDEN).json({
      success: false,
      error: ERROR_MESSAGES.USER_ONLY,
    });
  }
  next();
};

module.exports = {
  isAdmin,
  isUser,
};
  