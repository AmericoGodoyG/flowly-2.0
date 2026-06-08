const POSITIVE = new Set(['bom', 'boa', 'otimo', 'excelente', 'resolvido', 'concluido']);
const NEGATIVE = new Set(['ruim', 'erro', 'falha', 'atrasado', 'problema', 'travou', 'urgente']);
const SPAM = new Set(['spam', 'promocao', 'clique', 'oferta']);
const CONFLICT = new Set(['briga', 'brigar', 'conflito', 'discussao', 'culpa', 'culpado', 'incompetente', 'irresponsavel']);
const HELP = new Set(['ajuda', 'ajudar', 'duvida', 'travado', 'bloqueado', 'bloqueada', 'socorro', 'orientacao']);
const OFFENSIVE = new Set(['idiota', 'burro', 'lixo']);

const TOPIC_KEYWORDS = {
  tarefas: new Set(['tarefa', 'tarefas', 'backlog', 'status', 'cronometro']),
  equipes: new Set(['equipe', 'equipes', 'membro', 'membros', 'time']),
  usuarios: new Set(['usuario', 'usuarios', 'perfil']),
  chat: new Set(['chat', 'mensagem', 'mensagens', 'comentario']),
};

const stripAccents = (text) => String(text || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '');

const tokenize = (text) => stripAccents(text).toLowerCase().match(/[\wÀ-ÿ]+/g) || [];

const extractEntities = (text) => {
  const source = String(text || '');
  const entities = [];

  for (const objectId of source.match(/\b[a-fA-F0-9]{24}\b/g) || []) {
    entities.push({ type: 'object_id', value: objectId });
  }
  for (const mention of source.match(/@([\w._-]+)/g) || []) {
    entities.push({ type: 'mention', value: mention.slice(1) });
  }
  for (const properName of source.match(/\b[A-ZÀ-Ý][a-zà-ÿ]{2,}\b/g) || []) {
    entities.push({ type: 'proper_name', value: properName });
  }

  return entities.slice(0, 20);
};

const hasAny = (words, dictionary) => [...words].some((word) => dictionary.has(word));

const mineText = (text) => {
  const words = new Set(tokenize(text));
  let positiveHits = 0;
  let negativeHits = 0;

  words.forEach((word) => {
    if (POSITIVE.has(word)) positiveHits += 1;
    if (NEGATIVE.has(word)) negativeHits += 1;
  });

  const sentiment = positiveHits > negativeHits
    ? 'positivo'
    : negativeHits > positiveHits
      ? 'negativo'
      : 'neutro';

  const topics = Object.entries(TOPIC_KEYWORDS)
    .filter(([, keywords]) => hasAny(words, keywords))
    .map(([topic]) => topic);

  return {
    sentiment,
    topics: topics.length ? topics : ['chat'],
    entities: extractEntities(text),
    spamAlert: hasAny(words, SPAM),
    signals: [
      ...(hasAny(words, CONFLICT) ? ['conflict_language'] : []),
      ...(hasAny(words, HELP) ? ['help_request'] : []),
      ...(hasAny(words, OFFENSIVE) ? ['offensive_language'] : []),
    ],
  };
};

const analyzeConversationTrend = ({ currentInsight, recentInsights = [], blocked = false }) => {
  const window = [currentInsight, ...recentInsights].filter(Boolean);
  const total = Math.max(window.length, 1);
  const negativeCount = window.filter((item) => item.sentiment === 'negativo').length;
  const blockedCount = window.filter((item) => item.blocked || item.alertLevel === 'high').length + (blocked ? 1 : 0);
  const conflictCount = window.filter((item) => (item.signals || []).includes('conflict_language')).length;
  const helpCount = window.filter((item) => (item.signals || []).includes('help_request')).length;
  const offensiveCount = window.filter((item) => (item.signals || []).includes('offensive_language')).length + blockedCount;

  const signals = new Set(currentInsight.signals || []);
  if (blocked || offensiveCount >= 2) signals.add('offensive_language_excess');
  if (conflictCount >= 2 || negativeCount / total >= 0.45) signals.add('possible_conflict');
  if (helpCount >= 2) signals.add('team_help_needed');

  const conflictRisk = Math.min(
    1,
    (negativeCount / total) * 0.35
      + Math.min(conflictCount / 3, 1) * 0.3
      + Math.min(offensiveCount / 3, 1) * 0.25
      + Math.min(helpCount / 4, 1) * 0.1
  );

  const helpNeeded = signals.has('team_help_needed') || helpCount >= 2 || conflictRisk >= 0.65;
  const alertLevel = blocked || conflictRisk >= 0.75 || offensiveCount >= 3
    ? 'high'
    : conflictRisk >= 0.5 || helpNeeded
      ? 'medium'
      : conflictRisk >= 0.3
        ? 'low'
        : 'none';

  let recommendation = '';
  if (alertLevel === 'high') {
    recommendation = 'Intervenha na equipe: ha sinais fortes de conflito, linguagem ofensiva ou escalada negativa.';
  } else if (helpNeeded) {
    recommendation = 'Acompanhe a equipe: ha indicios de duvidas recorrentes ou necessidade de orientacao.';
  } else if (alertLevel === 'medium') {
    recommendation = 'Observe a conversa: o tom indica possivel atrito ou dificuldade operacional.';
  }

  return {
    alertLevel,
    conflictRisk: Number(conflictRisk.toFixed(2)),
    helpNeeded,
    signals: [...signals],
    recommendation,
  };
};

module.exports = {
  mineText,
  analyzeConversationTrend,
};
