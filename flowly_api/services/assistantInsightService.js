const AssistantInsight = require('../models/AssistantInsight');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { mineText, analyzeConversationTrend } = require('./nlpMiningService');
const { notifyUsers } = require('../utils/notificationService');

const ALERT_COOLDOWN_MS = 60 * 60 * 1000;

const recentTeamInsights = async (teamId, limit = 12) => AssistantInsight.find({
  teamId,
  source: 'team_chat',
})
  .sort({ createdAt: -1 })
  .limit(limit)
  .select('sentiment signals alertLevel helpNeeded conflictRisk')
  .lean();

const adminRecipientsForTeam = async (equipe) => {
  const recipients = new Set();
  if (equipe.createdBy) {
    recipients.add(String(equipe.createdBy));
  }

  const memberIds = (equipe.membros || []).map((membro) => String(membro._id || membro));
  if (memberIds.length) {
    const adminMembers = await User.find({ _id: { $in: memberIds }, tipo: 'admin' }).select('_id').lean();
    adminMembers.forEach((admin) => recipients.add(String(admin._id)));
  }

  return [...recipients];
};

const maybeNotifyCriticalInsight = async ({ document, equipe }) => {
  if (!['medium', 'high'].includes(document.alertLevel) && !document.helpNeeded) {
    return;
  }

  const since = new Date(Date.now() - ALERT_COOLDOWN_MS);
  const recentNotification = await Notification.findOne({
    tipo: 'system',
    createdAt: { $gte: since },
    'metadata.kind': 'team_insight_alert',
    'metadata.equipeId': String(equipe._id),
    'metadata.alertLevel': document.alertLevel,
  }).select('_id');

  if (recentNotification) {
    return;
  }

  const userIds = await adminRecipientsForTeam(equipe);
  if (!userIds.length) {
    return;
  }

  const risco = Math.round((document.conflictRisk || 0) * 100);
  const actor = await User.findById(document.userId).select('nome email').lean();
  const actorName = actor?.nome || actor?.email || 'Um usuario';
  const signals = document.signals || [];
  const behaviorAlert = signals.some((signal) => [
    'offensive_language',
    'offensive_language_excess',
    'blocked_message',
  ].includes(signal));
  const texto = behaviorAlert
    ? `Alerta de comportamento na equipe ${equipe.nome}: ${actorName} teve sinais de linguagem inadequada ou bloqueios recorrentes. Risco ${risco}%.`
    : document.alertLevel === 'high'
      ? `Alerta critico na equipe ${equipe.nome}: sinais de conflito ou linguagem ofensiva recorrente. Risco ${risco}%.`
      : `Acompanhamento recomendado na equipe ${equipe.nome}: possivel necessidade de ajuda. Risco ${risco}%.`;

  await notifyUsers({
    userIds,
    texto,
    tipo: 'system',
    origemId: document._id,
    metadata: {
      kind: 'team_insight_alert',
      equipeId: String(equipe._id),
      insightId: String(document._id),
      alertLevel: document.alertLevel,
      conflictRisk: document.conflictRisk,
      signals: document.signals || [],
      userId: String(document.userId),
      userName: actorName,
    },
  });
};

const upsertInsight = async ({ eventId, messageId, content, equipe, userId, source, blocked = false }) => {
  const mined = mineText(content);
  const currentInsight = {
    ...mined,
    blocked,
    alertLevel: blocked ? 'high' : 'none',
    signals: [...new Set([...(mined.signals || []), ...(blocked ? ['blocked_message'] : [])])],
  };
  const recentInsights = await recentTeamInsights(equipe._id);
  const trend = analyzeConversationTrend({ currentInsight, recentInsights, blocked });

  const document = await AssistantInsight.findOneAndUpdate(
    { eventId },
    {
      eventId,
      userId: String(userId),
      channelId: String(equipe._id),
      teamId: equipe._id,
      teamName: equipe.nome,
      content,
      source,
      eventCreatedAt: new Date(),
      sentiment: mined.sentiment,
      topics: mined.topics,
      entities: mined.entities,
      spamAlert: Boolean(mined.spamAlert || blocked),
      alertLevel: trend.alertLevel,
      conflictRisk: trend.conflictRisk,
      helpNeeded: trend.helpNeeded,
      signals: trend.signals,
      recommendation: trend.recommendation,
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  await maybeNotifyCriticalInsight({ document, equipe });
  return document;
};

const saveChatInsight = async ({ message, equipe, userId }) => upsertInsight({
  eventId: `chat:${message._id}`,
  messageId: message._id,
  content: message.texto,
  equipe,
  userId,
  source: 'team_chat',
});

const saveBlockedChatInsight = async ({ texto, equipe, userId, reason }) => upsertInsight({
  eventId: `chat_blocked:${equipe._id}:${userId}:${Date.now()}`,
  content: `${texto}\nMotivo do bloqueio: ${reason}`,
  equipe,
  userId,
  source: 'team_chat_blocked',
  blocked: true,
});

module.exports = {
  saveChatInsight,
  saveBlockedChatInsight,
};
