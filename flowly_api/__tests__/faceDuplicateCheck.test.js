const { cosineDistance } = require('../utils/faceDistance');

describe('faceDuplicateCheck', () => {
  it('deve retornar distância zero para embeddings idênticos', () => {
    const embedding = [0.2, 0.4, 0.6, 0.8];
    expect(cosineDistance(embedding, embedding)).toBeCloseTo(0, 10);
  });

  it('deve retornar distância alta para embeddings diferentes', () => {
    const source = [1, 0, 0];
    const probe = [0, 1, 0];
    expect(cosineDistance(source, probe)).toBe(1);
  });

  it('deve retornar distância baixa para embeddings similares', () => {
    const source = [0.9, 0.1, 0.05];
    const probe = [0.88, 0.12, 0.04];
    expect(cosineDistance(source, probe)).toBeLessThan(0.01);
  });
});
