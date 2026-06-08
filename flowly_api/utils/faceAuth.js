const jwt = require('jsonwebtoken');
const config = require('../config/config');
const { getSignedUrl } = require('../services/storage');

const buildUserPayload = async (user) => ({
  id: user._id,
  nome: user.nome,
  tipo: user.tipo,
  fotoPerfil: await getSignedUrl(user.fotoPerfil),
});

const issueAuthToken = (user) =>
  jwt.sign({ id: user._id, tipo: user.tipo }, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn || '1d',
  });

const issueFaceSessionToken = (userId, purpose) => {
  const expiresIn =
    purpose === 'face_enroll'
      ? config.face.enrollSessionExpiresIn
      : config.face.sessionExpiresIn;

  return jwt.sign({ id: userId, purpose }, config.jwt.secret, { expiresIn });
};

const verifyFaceSessionToken = (token, expectedPurpose) => {
  const decoded = jwt.verify(token, config.jwt.secret);

  if (!decoded?.id || decoded.purpose !== expectedPurpose) {
    const error = new Error('Token de sessão facial inválido.');
    error.statusCode = 401;
    throw error;
  }

  return decoded;
};

module.exports = {
  buildUserPayload,
  issueAuthToken,
  issueFaceSessionToken,
  verifyFaceSessionToken,
};
