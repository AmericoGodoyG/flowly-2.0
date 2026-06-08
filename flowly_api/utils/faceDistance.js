function cosineDistance(source, probe) {
  if (!source?.length || !probe?.length || source.length !== probe.length) {
    return 1;
  }

  let dot = 0;
  let normSource = 0;
  let normProbe = 0;

  for (let index = 0; index < source.length; index += 1) {
    const sourceValue = Number(source[index]);
    const probeValue = Number(probe[index]);
    dot += sourceValue * probeValue;
    normSource += sourceValue * sourceValue;
    normProbe += probeValue * probeValue;
  }

  const norm = Math.sqrt(normSource) * Math.sqrt(normProbe);
  if (!norm) {
    return 1;
  }

  return 1 - dot / norm;
}

module.exports = {
  cosineDistance,
};
