const Notification = require('../models/Notification');
const { getIo } = require('./socketInstance');

const serializeNotification = (notificationDoc) => ({
  _id: notificationDoc._id,
  texto: notificationDoc.texto,
  user: notificationDoc.user,
  tipo: notificationDoc.tipo,
  origemId: notificationDoc.origemId,
  metadata: notificationDoc.metadata || {},
  lida: notificationDoc.lida,
  createdAt: notificationDoc.createdAt,
  updatedAt: notificationDoc.updatedAt,
});

const notifyUsers = async ({ userIds = [], texto, tipo = 'system', origemId = null, metadata = {} }) => {
  const uniqueUserIds = [...new Set(userIds.map((id) => String(id).trim()).filter(Boolean))];

  if (uniqueUserIds.length === 0 || !texto) {
    return [];
  }

  const notifications = await Notification.insertMany(
    uniqueUserIds.map((userId) => ({
      texto,
      user: userId,
      tipo,
      origemId,
      metadata,
      lida: false,
    }))
  );

  const io = getIo();
  if (io) {
    notifications.forEach((notificationDoc) => {
      io.to(`user_${notificationDoc.user.toString()}`).emit('notification_created', serializeNotification(notificationDoc));
    });
  }

  return notifications;
};

module.exports = {
  notifyUsers,
  serializeNotification,
};