const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_SERVER_ERROR: 500,
};

const ERROR_MESSAGES = {
  TOKEN_NOT_PROVIDED: 'Token não fornecido',
  INVALID_TOKEN: 'Token inválido',
  ROUTE_NOT_FOUND: 'Rota não encontrada',
  INTERNAL_ERROR: 'Erro interno do servidor',
  UNAUTHORIZED_ACCESS: 'Acesso restrito',
  ADMIN_ONLY: 'Acesso restrito a administradores',
  USER_ONLY: 'Acesso restrito a usuários',
};

const USER_TYPES = {
  ADMIN: 'admin',
  USER: 'user',
};

module.exports = {
  HTTP_STATUS,
  ERROR_MESSAGES,
  USER_TYPES,
};
