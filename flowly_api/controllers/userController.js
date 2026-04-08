const argon2 = require('argon2');
const User = require('../models/User');

exports.listarUsers = async (req, res) => {
  try {
    const users = await User.find().select('nome email tipo fotoPerfil');
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

    if (req.file) {
      user.fotoPerfil = `/uploads/${req.file.filename}`;
    }

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
