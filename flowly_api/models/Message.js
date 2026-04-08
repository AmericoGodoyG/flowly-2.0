const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  texto: { type: String, required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  equipe: { type: mongoose.Schema.Types.ObjectId, ref: 'Equipe', required: true }
}, { timestamps: true });

module.exports = mongoose.model('Message', messageSchema);
