const AssistantInsight = require('../models/AssistantInsight');
const { mineText } = require('./nlpMiningService');

const saveChatInsight = async ({ message, equipe, userId }) => {
  const insight = mineText(message.texto);

  await AssistantInsight.findOneAndUpdate(
    { eventId: `chat:${message._id}` },
    {
      eventId: `chat:${message._id}`,
      userId: String(userId),
      channelId: String(equipe._id),
      teamId: equipe._id,
      teamName: equipe.nome,
      content: message.texto,
      source: 'team_chat',
      eventCreatedAt: message.createdAt || new Date(),
      sentiment: insight.sentiment,
      topics: insight.topics,
      entities: insight.entities,
      spamAlert: insight.spamAlert,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
};

module.exports = {
  saveChatInsight,
};
