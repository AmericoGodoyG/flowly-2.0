const express = require('express');
const cors = require('cors');
const config = require('./config/config');
const errorHandler = require('./middlewares/errorHandler');
const { HTTP_STATUS, ERROR_MESSAGES } = require('./config/constants');

// Routes
const authRoutes = require('./routes/authRoutes');
const equipeRoutes = require('./routes/equipesRoutes');
const tarefaRoutes = require('./routes/tarefaRoutes');
const adminRoutes = require('./routes/adminRoutes');
const userRoutes = require('./routes/userRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const storageRoutes = require('./routes/storageRoutes');
const faceRoutes = require('./routes/faceRoutes');

const app = express();

// Middleware
app.use(cors({ origin: config.corsOrigin }));
app.use(express.json({ limit: config.bodySizeLimit }));
app.use(express.urlencoded({ extended: true, limit: config.bodySizeLimit }));

const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/equipes', equipeRoutes);
app.use('/api/tarefas', tarefaRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/notificacoes', notificationRoutes);
app.use('/api/storage', storageRoutes);
app.use('/api/face', faceRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(HTTP_STATUS.NOT_FOUND).json({
    success: false,
    error: ERROR_MESSAGES.ROUTE_NOT_FOUND,
  });
});

// Error Handler (deve ser o último middleware)
app.use(errorHandler);

module.exports = app;
