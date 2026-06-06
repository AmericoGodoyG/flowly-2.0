const bucket = require('../services/storage');
const { verifyFileAccessToken } = require('../services/storage');

exports.downloadFile = async (req, res) => {
  try {
    const { encodedPath } = req.params;
    const { token } = req.query;

    if (!token) {
      return res.status(401).json({ erro: 'Token do arquivo nao informado' });
    }

    const filePath = verifyFileAccessToken(token, encodedPath);
    const file = bucket.file(filePath);
    const [exists] = await file.exists();

    if (!exists) {
      return res.status(404).json({ erro: 'Arquivo nao encontrado' });
    }

    const [metadata] = await file.getMetadata();
    if (metadata.contentType) {
      res.setHeader('Content-Type', metadata.contentType);
    }
    if (metadata.size) {
      res.setHeader('Content-Length', metadata.size);
    }
    res.setHeader('Cache-Control', 'private, max-age=300');

    file.createReadStream()
      .on('error', (error) => {
        console.error('Erro ao ler arquivo do bucket:', error);
        if (!res.headersSent) {
          res.status(500).json({ erro: 'Erro ao ler arquivo' });
        } else {
          res.destroy(error);
        }
      })
      .pipe(res);
  } catch (error) {
    console.error('Erro ao validar acesso ao arquivo:', error.message);
    res.status(401).json({ erro: 'Acesso ao arquivo invalido ou expirado' });
  }
};
