require('dotenv').config();

const config = {
  port: process.env.PORT || 5000,
  mongodb: {
    uri: process.env.MONGO_URI || 'mongodb://localhost:27017/Flowly',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'sua_chave_secreta',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  env: process.env.NODE_ENV || 'development',
  corsOrigin: process.env.CORS_ORIGIN || '*',
};

module.exports = config;
