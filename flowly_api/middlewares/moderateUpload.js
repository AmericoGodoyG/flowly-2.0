const { verifyUploadContent } = require('../services/uploadSafetyService');

const moderateUpload = (context) => async (req, res, next) => {
  try {
    if (!req.file) {
      return next();
    }

    const result = await verifyUploadContent({ file: req.file, context });
    req.fileModeration = result;

    if (!result.allowed) {
      return res.status(422).json({
        erro: 'Arquivo bloqueado pela verificacao de seguranca',
        detalhe: result.reason,
        categorias: result.categories || [],
        provider: result.provider,
        ...(process.env.NODE_ENV === 'development' && result.detail ? { debug: result.detail } : {}),
      });
    }

    return next();
  } catch (error) {
    console.error('Erro na moderacao de upload:', error);
    return res.status(422).json({
      erro: 'Nao foi possivel verificar o conteudo do arquivo',
      detalhe: error.message,
    });
  }
};

module.exports = moderateUpload;
