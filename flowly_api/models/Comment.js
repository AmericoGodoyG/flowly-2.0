const mongoose = require('mongoose');

const commentSchema = new mongoose.Schema({
  texto: { type: String, required: true },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  tarefa: { type: mongoose.Schema.Types.ObjectId, ref: 'Tarefa', required: true }
}, { timestamps: true });

module.exports = mongoose.model('Comment', commentSchema);
