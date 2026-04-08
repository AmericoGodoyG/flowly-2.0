const mongoose = require('mongoose');

const equipeSchema = new mongoose.Schema({
  nome: { type: String, required: true },
  code: {
    type: String,
    required: true,
    unique: true,
    default: () => new mongoose.Types.ObjectId().toString(),
  },
  membros: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }]
}, { timestamps: true });

module.exports = mongoose.model('Equipe', equipeSchema);