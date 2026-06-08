const { cosineDistance } = require('../utils/faceDistance');
const {
  getStoredEmbeddings,
  minDistanceToReferences,
  matchesReferences,
  normalizeEmbeddingList,
} = require('../utils/faceEmbeddings');

describe('faceEmbeddings', () => {
  it('deve usar embedding legado quando embeddings não existir', () => {
    const profile = { embedding: [1, 0, 0] };
    expect(getStoredEmbeddings(profile)).toEqual([[1, 0, 0]]);
  });

  it('deve preferir lista embeddings quando disponível', () => {
    const profile = {
      embedding: [1, 0, 0],
      embeddings: [
        [1, 0, 0],
        [0.9, 0.1, 0],
      ],
    };
    expect(getStoredEmbeddings(profile)).toHaveLength(2);
  });

  it('deve aceitar match se qualquer referência estiver dentro do limiar', () => {
    const references = [
      [1, 0, 0],
      [0, 1, 0],
    ];
    const probe = [0.98, 0.02, 0];
    expect(matchesReferences(references, probe, 0.46)).toBe(true);
    expect(minDistanceToReferences(references, probe)).toBeLessThan(0.05);
  });

  it('deve normalizar embedding único em lista', () => {
    expect(normalizeEmbeddingList([1, 2, 3])).toEqual([[1, 2, 3]]);
  });

  it('deve calcular distância mínima entre referências', () => {
    const references = [
      [1, 0, 0],
      [0, 1, 0],
    ];
    expect(minDistanceToReferences(references, [0, 1, 0])).toBeCloseTo(0, 10);
    expect(cosineDistance([1, 0, 0], [0, 1, 0])).toBe(1);
  });
});
