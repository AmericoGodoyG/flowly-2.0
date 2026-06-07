const AssistantInsight = require('../models/AssistantInsight');
const Equipe = require('../models/Equipe');

const buildSuggestions = ({ sentiments = {}, topTopics = [], spamAlerts = 0, totalMessages = 0 }) => {
  const suggestions = [];
  const negative = sentiments.negativo || 0;
  const neutral = sentiments.neutro || 0;
  const negativeRatio = totalMessages > 0 ? negative / totalMessages : 0;
  const neutralRatio = totalMessages > 0 ? neutral / totalMessages : 0;
  const topicNames = topTopics.map((item) => item.topic);

  if (negativeRatio >= 0.35) {
    suggestions.push('Priorize uma conversa com a equipe: há volume relevante de mensagens negativas.');
  }
  if (neutralRatio >= 0.6 && totalMessages >= 5) {
    suggestions.push('Estimule feedbacks mais objetivos: muitas mensagens estão neutras e podem esconder dúvidas não verbalizadas.');
  }
  if (topicNames.includes('tarefas')) {
    suggestions.push('Revise clareza de tarefas, status e responsabilidades com a equipe.');
  }
  if (topicNames.includes('equipes')) {
    suggestions.push('Verifique dúvidas sobre composição, papéis ou comunicação da equipe.');
  }
  if (topicNames.includes('chat')) {
    suggestions.push('Acompanhe conversas e comentários: o time pode estar usando o assistente para dúvidas operacionais.');
  }
  if (spamAlerts > 0) {
    suggestions.push('Investigue alertas de spam ou uso inadequado no canal da equipe.');
  }
  if (suggestions.length === 0) {
    suggestions.push('Nenhum ponto crítico detectado. Continue acompanhando os tópicos recorrentes.');
  }

  return suggestions;
};

const buildAggregation = async () => {
  const [totalMessages, sentimentRows, topicRows, spamAlerts, recent, teamRows] = await Promise.all([
    AssistantInsight.countDocuments(),
    AssistantInsight.aggregate([
      { $group: { _id: '$sentiment', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]),
    AssistantInsight.aggregate([
      { $unwind: '$topics' },
      { $group: { _id: '$topics', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 },
    ]),
    AssistantInsight.countDocuments({ spamAlert: true }),
    AssistantInsight.find()
      .sort({ createdAt: -1 })
      .limit(12)
      .select('userId channelId teamId teamName content sentiment topics spamAlert createdAt')
      .lean(),
    AssistantInsight.aggregate([
      {
        $facet: {
          totals: [
            {
              $group: {
                _id: { $ifNull: ['$teamId', '$channelId'] },
                totalMessages: { $sum: 1 },
                spamAlerts: { $sum: { $cond: ['$spamAlert', 1, 0] } },
              },
            },
          ],
          sentiments: [
            {
              $group: {
                _id: {
                  teamKey: { $ifNull: ['$teamId', '$channelId'] },
                  sentiment: '$sentiment',
                },
                count: { $sum: 1 },
              },
            },
          ],
          topics: [
            { $unwind: '$topics' },
            {
              $group: {
                _id: {
                  teamKey: { $ifNull: ['$teamId', '$channelId'] },
                  topic: '$topics',
                },
                count: { $sum: 1 },
              },
            },
            { $sort: { count: -1 } },
          ],
        },
      },
    ]),
  ]);

  const sentiments = sentimentRows.reduce((acc, row) => {
    acc[row._id || 'neutro'] = row.count;
    return acc;
  }, { positivo: 0, neutro: 0, negativo: 0 });

  const teamFacet = teamRows[0] || { totals: [], sentiments: [], topics: [] };
  const teamIds = teamFacet.totals.map((row) => String(row._id || 'web'));
  const equipes = await Equipe.find({ _id: { $in: teamIds.filter((id) => /^[a-fA-F0-9]{24}$/.test(id)) } })
    .select('nome')
    .lean();
  const teamNames = equipes.reduce((acc, equipe) => {
    acc[String(equipe._id)] = equipe.nome;
    return acc;
  }, {});

  const byTeam = teamFacet.totals.map((row) => {
    const channelId = String(row._id || 'web');
    const sentimentsByTeam = teamFacet.sentiments
      .filter((item) => String(item._id.teamKey || 'web') === channelId)
      .reduce((acc, item) => {
        acc[item._id.sentiment || 'neutro'] = item.count;
        return acc;
      }, { positivo: 0, neutro: 0, negativo: 0 });
    const topTopics = teamFacet.topics
      .filter((item) => String(item._id.teamKey || 'web') === channelId)
      .slice(0, 6)
      .map((item) => ({ topic: item._id.topic, count: item.count }));
    const teamInsight = {
      channelId,
      teamName: teamNames[channelId] || (channelId === 'web' ? 'Canal Web' : `Equipe ${channelId.slice(-6)}`),
      totalMessages: row.totalMessages,
      spamAlerts: row.spamAlerts,
      sentiments: sentimentsByTeam,
      topTopics,
    };
    return {
      ...teamInsight,
      suggestions: buildSuggestions(teamInsight),
    };
  }).sort((a, b) => b.totalMessages - a.totalMessages);

  const globalInsight = {
    totalMessages,
    sentiments,
    topTopics: topicRows.map((row) => ({ topic: row._id, count: row.count })),
    spamAlerts,
    recent,
    byTeam,
  };

  return {
    ...globalInsight,
    suggestions: buildSuggestions(globalInsight),
  };
};

const ingestAssistantInsight = async (req, res) => {
  const expectedSecret = process.env.ASSISTANT_ANALYTICS_SECRET || '';
  const receivedSecret = req.headers['x-assistant-secret'];

  if (expectedSecret && receivedSecret !== expectedSecret) {
    return res.status(401).json({ success: false, error: 'Segredo interno inválido' });
  }

  const { event, insight } = req.body || {};
  if (!event?.id || !event?.userId || !event?.content || !insight) {
    return res.status(400).json({ success: false, error: 'Payload de insight inválido' });
  }

  try {
    const document = await AssistantInsight.findOneAndUpdate(
      { eventId: event.id },
      {
        eventId: event.id,
        userId: String(event.userId),
        channelId: event.channelId || 'web',
        teamId: /^[a-fA-F0-9]{24}$/.test(String(event.teamId || event.channelId || ''))
          ? String(event.teamId || event.channelId)
          : undefined,
        teamName: event.teamName || undefined,
        content: String(event.content),
        source: event.source || 'frontend',
        eventCreatedAt: event.createdAt ? new Date(event.createdAt) : undefined,
        sentiment: insight.sentiment || 'neutro',
        topics: Array.isArray(insight.topics) ? insight.topics : [],
        entities: Array.isArray(insight.entities) ? insight.entities : [],
        spamAlert: Boolean(insight.spam_alert ?? insight.spamAlert),
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    return res.status(201).json({ success: true, id: document._id });
  } catch (err) {
    return res.status(500).json({ success: false, error: 'Erro ao salvar insight do assistente' });
  }
};

const getAssistantInsights = async (_req, res) => {
  try {
    const insights = await buildAggregation();
    return res.json({ success: true, insights });
  } catch (err) {
    return res.status(500).json({ success: false, error: 'Erro ao carregar insights do assistente' });
  }
};

module.exports = {
  ingestAssistantInsight,
  getAssistantInsights,
};
