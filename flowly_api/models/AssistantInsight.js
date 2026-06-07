const mongoose = require('mongoose');

const entitySchema = new mongoose.Schema(
  {
    type: { type: String, required: true, trim: true },
    value: { type: String, required: true, trim: true },
  },
  { _id: false }
);

const assistantInsightSchema = new mongoose.Schema(
  {
    eventId: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    channelId: { type: String, default: 'web', index: true },
    teamId: { type: mongoose.Schema.Types.ObjectId, ref: 'Equipe', index: true },
    teamName: { type: String, trim: true },
    content: { type: String, required: true },
    source: { type: String, default: 'frontend' },
    eventCreatedAt: { type: Date },
    sentiment: {
      type: String,
      enum: ['positivo', 'neutro', 'negativo'],
      default: 'neutro',
      index: true,
    },
    topics: [{ type: String, index: true }],
    entities: [entitySchema],
    spamAlert: { type: Boolean, default: false, index: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('AssistantInsight', assistantInsightSchema);
