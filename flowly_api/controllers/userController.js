const argon2 = require('argon2');
const User = require('../models/User');
const upload = require('../middlewares/upload');
const path = require('path');
const bucket = require('../services/storage');

exports.listarUsers = async (req, res) => {
  try {
    const users = await User.find().select('nome email tipo fotoPerfil');
    res.json(users);
  } catch (error) {
    console.error('Erro ao buscar usuarios:', error);
    res.status(500).json({ error: 'Erro ao buscar usuarios' });
  }
};

exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.trim().length === 0) {
      return res.json([]);
    }

    const searchQuery = q.trim();
    const users = await User.find({
      tipo: { $in: ['admin', 'user'] },
      $or: [
        { nome: { $regex: searchQuery, $options: 'i' } },
        { email: { $regex: searchQuery, $options: 'i' } },
      ],
    })
      .select('_id nome email fotoPerfil tipo')
      .limit(10);

    res.json(users);
  } catch (error) {
    console.error('Erro ao buscar usuarios:', error);
    res.status(500).json({ error: 'Erro ao buscar usuarios' });
  }
};

exports.me = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('nome email tipo fotoPerfil');

    if (!user) {
      return res.status(404).json({ erro: 'Usuario nao encontrado' });
    }

    res.json(user);
  } catch (error) {
    console.error('Erro ao buscar perfil:', error);
    res.status(500).json({ erro: 'Erro ao buscar perfil' });
  }
};

exports.atualizarPerfil = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({ erro: 'Usuario nao encontrado' });
    }

    if (typeof req.body.nome === 'string' && req.body.nome.trim()) {
      user.nome = req.body.nome.trim();
    }

    // Se arquivo foi fornecido, fazer upload
    if (req.file) {
      // Validação do arquivo
      const maxFileSize = 5 * 1024 * 1024; // 5MB
      if (req.file.size > maxFileSize) {
        return res.status(400).json({ erro: 'Arquivo muito grande (máximo 5MB)' });
      }

      const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
      if (!allowedMimeTypes.includes(req.file.mimetype)) {
        return res.status(400).json({ erro: 'Tipo de arquivo não permitido' });
      }

      try {
        // Upload para Cloud Storage
        const publicUrl = await uploadFotoParaGCS(req.file);
        user.fotoPerfil = publicUrl;
      } catch (uploadError) {
        console.error('Erro ao fazer upload para Google Cloud Storage:', uploadError);
        
        // Diferenciar tipos de erro
        if (uploadError.message.includes('timeout') || uploadError.code === 'ETIMEDOUT') {
          return res.status(504).json({ erro: 'Timeout ao conectar com Cloud Storage' });
        }
        if (uploadError.message.includes('auth') || uploadError.code === 403) {
          return res.status(500).json({ erro: 'Erro de autenticação com Cloud Storage' });
        }
        if (uploadError.message.includes('quota') || uploadError.code === 429) {
          return res.status(429).json({ erro: 'Limite de armazenamento atingido' });
        }
        
        return res.status(500).json({ erro: 'Erro ao fazer upload da foto de perfil' });
      }
    }

    // Salvar usuário apenas após sucesso do upload (se houver)
    await user.save();

    res.json({
      msg: 'Perfil atualizado com sucesso',
      user: {
        id: user._id,
        nome: user.nome,
        email: user.email,
        tipo: user.tipo,
        fotoPerfil: user.fotoPerfil,
      },
    });
  } catch (error) {
    console.error('Erro ao atualizar perfil:', error);
    res.status(500).json({ erro: 'Erro ao atualizar perfil' });
  }
};

/**
 * Função auxiliar para upload de foto com timeout
 * @param {Object} file - Objeto do arquivo (req.file)
 * @returns {Promise<string>} URL pública do arquivo
 */
const uploadFotoParaGCS = (file) => {
  return new Promise((resolve, reject) => {
    let uploadTimeout;
    let isResolved = false;
    let blobStream;

    try {
      const uniqueName =
        Date.now() +
        '-' +
        Math.round(Math.random() * 1e9) +
        path.extname(file.originalname);

      const blob = bucket.file(uniqueName);

      blobStream = blob.createWriteStream({
        resumable: false,
        metadata: {
          contentType: file.mimetype
        }
      });

      // Timeout de 30 segundos
      uploadTimeout = setTimeout(() => {
        if (!isResolved) {
          isResolved = true;
          // Destruir o stream se ainda estiver ativo
          if (blobStream && !blobStream.destroyed) {
            blobStream.destroy();
          }
          reject(new Error('timeout: Upload excedeu o tempo limite de 30 segundos'));
        }
      }, 30000);

      blobStream.on('error', (err) => {
        if (!isResolved) {
          isResolved = true;
          clearTimeout(uploadTimeout);
          reject(err);
        }
      });

      blobStream.on('finish', () => {
        if (!isResolved) {
          isResolved = true;
          clearTimeout(uploadTimeout);
          const publicUrl = `https://storage.googleapis.com/${bucket.name}/${blob.name}`;
          resolve(publicUrl);
        }
      });

      // Escrever apenas se o stream não foi destruído
      if (blobStream && !blobStream.destroyed) {
        blobStream.end(file.buffer);
      } else {
        throw new Error('Stream foi destruído antes de iniciar o upload');
      }
    } catch (error) {
      if (uploadTimeout) clearTimeout(uploadTimeout);
      if (!isResolved) {
        isResolved = true;
        // Destruir o stream se existir
        if (blobStream && !blobStream.destroyed) {
          blobStream.destroy();
        }
        reject(error);
      }
    }
  });
};

exports.atualizarSenha = async (req, res) => {
  try {
    const { senhaAtual, novaSenha } = req.body;

    if (!senhaAtual || !novaSenha) {
      return res.status(400).json({ erro: 'Senha atual e nova senha sao obrigatorias' });
    }

    if (novaSenha.length < 6) {
      return res.status(400).json({ erro: 'Nova senha deve ter ao menos 6 caracteres' });
    }

    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({ erro: 'Usuario nao encontrado' });
    }

    const senhaValida = await argon2.verify(user.senha, senhaAtual);

    if (!senhaValida) {
      return res.status(401).json({ erro: 'Senha atual invalida' });
    }

    user.senha = await argon2.hash(novaSenha);
    await user.save();

    res.json({ msg: 'Senha atualizada com sucesso' });
  } catch (error) {
    console.error('Erro ao atualizar senha:', error);
    res.status(500).json({ erro: 'Erro ao atualizar senha' });
  }
};
