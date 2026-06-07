const BLOCKED_PATTERNS = [
  /\b(matar|espancar|viol[eê]ncia|amea[cç]a)\b/i,
  /\b(filho da puta|idiota|burro|lixo)\b/i,
  /\b(spam|promo[cç][aã]o imperd[ií]vel|clique aqui)\b/i,
];

const moderateText = (text) => {
  const normalized = String(text || '').trim().replace(/\s+/g, ' ');

  if (!normalized) {
    return { allowed: false, reason: 'empty_content', score: 1 };
  }

  const blocked = BLOCKED_PATTERNS.some((pattern) => pattern.test(normalized));
  if (blocked) {
    return { allowed: false, reason: 'unsafe_content', score: 0.95 };
  }

  if (normalized.length > 4000) {
    return { allowed: false, reason: 'possible_spam', score: 0.8 };
  }

  return { allowed: true, reason: '', score: 0.02 };
};

module.exports = {
  moderateText,
};
