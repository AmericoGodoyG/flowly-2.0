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

const DUPLICATE_FACE_MESSAGE =
  'Este rosto já está vinculado a outra conta Flowly. Use apenas uma conta por pessoa ou entre com a conta original.';

const CONTEXT_MESSAGES = {
  verify: {
    faceNotDetected:
      'Não identificamos seu rosto na foto. Olhe de frente para a câmera, com boa iluminação, e capture novamente para concluir o login.',
    multipleFaces:
      'Detectamos mais de um rosto na imagem. Certifique-se de que apenas você apareça na foto antes de tentar entrar.',
    generic: 'Não foi possível concluir a verificação facial. Tente capturar outra foto.',
  },
  enroll: {
    faceNotDetected:
      'Não identificamos um rosto na foto. Olhe de frente para a câmera, com boa iluminação, e capture novamente para cadastrar.',
    multipleFaces:
      'Detectamos mais de um rosto na imagem. Certifique-se de que apenas você apareça na foto.',
    generic: 'Não foi possível cadastrar a verificação facial. Tente capturar outra foto.',
  },
  profile: {
    faceNotDetected:
      'Não identificamos um rosto na foto. Olhe de frente para a câmera e capture novamente para atualizar sua verificação facial.',
    multipleFaces:
      'Detectamos mais de um rosto na imagem. Certifique-se de que apenas você apareça na foto.',
    generic: 'Não foi possível atualizar a verificação facial. Tente capturar outra foto.',
  },
};

function matchesAnyPattern(message, patterns) {
  return patterns.some((pattern) => message.includes(pattern));
}

export function getFaceErrorMessage(err, context = 'enroll') {
  const codigo = err?.response?.data?.codigo;
  if (codigo === 'FACE_DUPLICATE') {
    return DUPLICATE_FACE_MESSAGE;
  }

  if (err?.code === 'ECONNABORTED' || String(err?.message || '').toLowerCase().includes('timeout')) {
    return 'A verificação facial está demorando mais que o normal. Aguarde o processamento terminar e tente novamente.';
  }

  const raw =
    err?.response?.data?.erro ||
    err?.response?.data?.error ||
    err?.message ||
    '';

  if (!raw) {
    return CONTEXT_MESSAGES[context]?.generic || CONTEXT_MESSAGES.enroll.generic;
  }

  const message = String(raw).toLowerCase();
  const contextMessages = CONTEXT_MESSAGES[context] || CONTEXT_MESSAGES.enroll;

  if (
    message.includes('já está vinculado') ||
    message.includes('ja esta vinculado') ||
    message.includes('outra conta flowly')
  ) {
    return DUPLICATE_FACE_MESSAGE;
  }

  if (matchesAnyPattern(message, MULTIPLE_FACES_PATTERNS)) {
    return contextMessages.multipleFaces;
  }

  if (
    matchesAnyPattern(message, FACE_NOT_DETECTED_PATTERNS) ||
    /[a-z]:\\users\\|tmp[a-z0-9]+\.jpg|enforce_detection param/i.test(raw)
  ) {
    return contextMessages.faceNotDetected;
  }

  if (message.includes('não reconhecido') || message.includes('nao reconhecido')) {
    return 'Rosto não reconhecido. Tente capturar outra foto com o rosto bem visível.';
  }

  return raw;
}
