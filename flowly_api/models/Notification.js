const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  texto: { type: String, required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  tipo: { type: String, enum: ['chat', 'task', 'team', 'system'], default: 'system' },
  origemId: { type: mongoose.Schema.Types.ObjectId, required: false, default: null },
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  lida: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
