const FACE_NOT_DETECTED_PATTERNS = [
  'face could not be detected',
  'no face',
  'nenhum rosto',
  'could not be detected',
  'enforce_detection',
];

const MULTIPLE_FACES_PATTERNS = [
  'multiple faces',
  'more than one face',
  'mais de um rosto',
];

const DEFAULT_FACE_NOT_DETECTED_MESSAGE =
  'Não foi possível identificar um rosto na foto. Posicione-se de frente à câmera, com boa iluminação, e tente novamente.';

const MULTIPLE_FACES_MESSAGE =
  'Mais de um rosto foi detectado na imagem. Certifique-se de que apenas você apareça na foto.';

const GENERIC_FACE_ERROR_MESSAGE =
  'Não foi possível processar a foto. Tire outra imagem com o rosto bem visível e tente novamente.';

function matchesAnyPattern(message, patterns) {
  return patterns.some((pattern) => message.includes(pattern));
}

function normalizeFaceError(rawMessage, context = 'default') {
  if (!rawMessage || typeof rawMessage !== 'string') {
    return GENERIC_FACE_ERROR_MESSAGE;
  }

  const message = rawMessage.toLowerCase();

  if (matchesAnyPattern(message, MULTIPLE_FACES_PATTERNS)) {
    return MULTIPLE_FACES_MESSAGE;
  }

  if (matchesAnyPattern(message, FACE_NOT_DETECTED_PATTERNS)) {
    if (context === 'verify') {
      return (
        'Não identificamos seu rosto na foto. ' +
        'Olhe de frente para a câmera, com boa iluminação, e capture novamente para concluir o login.'
      );
    }

    if (context === 'profile') {
      return (
        'Não identificamos um rosto na foto. ' +
        'Olhe de frente para a câmera e capture novamente para atualizar sua verificação facial.'
      );
    }

    return DEFAULT_FACE_NOT_DETECTED_MESSAGE;
  }

  if (/[a-z]:\\users\\|tmp[a-z0-9]+\.jpg|enforce_detection param/i.test(rawMessage)) {
    return DEFAULT_FACE_NOT_DETECTED_MESSAGE;
  }

  return rawMessage;
}

module.exports = {
  normalizeFaceError,
  DEFAULT_FACE_NOT_DETECTED_MESSAGE,
  MULTIPLE_FACES_MESSAGE,
  GENERIC_FACE_ERROR_MESSAGE,
};
