const POSITIVE = new Set(['bom', 'boa', 'otimo', 'ótimo', 'excelente', 'resolvido', 'concluido', 'concluído']);
const NEGATIVE = new Set(['ruim', 'erro', 'falha', 'atrasado', 'problema', 'travou', 'urgente']);
const SPAM = new Set(['spam', 'promoção', 'promocao', 'clique', 'oferta']);

const TOPIC_KEYWORDS = {
  tarefas: new Set(['tarefa', 'tarefas', 'backlog', 'status', 'cronometro', 'cronômetro']),
  equipes: new Set(['equipe', 'equipes', 'membro', 'membros', 'time']),
  usuarios: new Set(['usuario', 'usuário', 'usuarios', 'usuários', 'perfil']),
  chat: new Set(['chat', 'mensagem', 'mensagens', 'comentario', 'comentário']),
};

const tokenize = (text) => String(text || '').toLowerCase().match(/[\wÀ-ÿ]+/g) || [];

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
    .filter(([, keywords]) => [...words].some((word) => keywords.has(word)))
    .map(([topic]) => topic);

  return {
    sentiment,
    topics: topics.length ? topics : ['chat'],
    entities: extractEntities(text),
    spamAlert: [...words].some((word) => SPAM.has(word)),
  };
};

module.exports = {
  mineText,
};
