const Equipe = require('../models/Equipe');
const User = require('../models/User');
const Message = require('../models/Message'); 
const mongoose = require('mongoose');
const { getSignedUrl } = require('../services/storage');

const assinarFotoUsuarioMensagem = async (message) => {
  const messageObject = typeof message.toObject === 'function' ? message.toObject() : message;

  if (!messageObject.user) {
    return messageObject;
  }

  return {
    ...messageObject,
    user: {
      ...messageObject.user,
      fotoPerfil: await getSignedUrl(messageObject.user.fotoPerfil),
    },
  };
};

const assinarFotosMembrosEquipe = async (equipe) => {
  const equipeObject = typeof equipe.toObject === 'function' ? equipe.toObject() : equipe;

  return {
    ...equipeObject,
    membros: await Promise.all((equipeObject.membros || []).map(async (membro) => {
      const membroObject = typeof membro.toObject === 'function' ? membro.toObject() : membro;

      if (!membroObject || typeof membroObject !== 'object') {
        return membroObject;
      }

      return {
        ...membroObject,
        fotoPerfil: await getSignedUrl(membroObject.fotoPerfil),
      };
    })),
  };
};

const assinarFotosMembrosEquipes = (equipes) => Promise.all(equipes.map(assinarFotosMembrosEquipe));

exports.criarEquipe = async (req, res) => {
  try {
    const { nome, membros } = req.body;

    // Validação do nome da equipe
    if (!nome || nome.trim() === "") {
      return res.status(400).json({ erro: "O nome da equipe é obrigatório" });
    }

    // Normaliza membros para IDs únicos e válidos; isso permite o mesmo colaborador em equipes diferentes.
    const membrosArray = Array.isArray(membros) ? membros : [];
    const membrosUnicos = [...new Set(membrosArray.map((id) => String(id).trim()))].filter(Boolean);

    const membrosInvalidos = membrosUnicos.filter((id) => !mongoose.isValidObjectId(id));
    if (membrosInvalidos.length > 0) {
      return res.status(400).json({ erro: 'Existem membros com identificadores inválidos' });
    }

    // Validar se todos os membros são usuarios
    const usuarios = await User.find({ _id: { $in: membrosUnicos }, tipo: 'user' }).select('_id');
    if (usuarios.length !== membrosUnicos.length) {
      return res.status(400).json({ erro: "Alguns membros não são usuarios válidos" });
    }

    // Criar a equipe
    const novaEquipe = new Equipe({ nome, membros: membrosUnicos, createdBy: req.user.id });
    await novaEquipe.save();

    // Retornar a equipe criada com os dados populados
    const equipePopulada = await Equipe.findById(novaEquipe._id).populate('membros', 'nome email fotoPerfil');
    res.status(201).json(await assinarFotosMembrosEquipe(equipePopulada));
  } catch (err) {
    res.status(500).json({ erro: "Erro ao criar equipe", detalhe: err.message });
  }
};

exports.listarEquipes = async (req, res) => {
  try {
    const equipes = await Equipe.find().populate('membros', 'nome email fotoPerfil');
    res.json(await assinarFotosMembrosEquipes(equipes));
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao listar equipes' });
  }
};

exports.listarMinhasEquipes = async (req, res) => {
  try {
    const filtro = req.user.tipo === 'admin' ? {} : { membros: req.user.id };
    const equipes = await Equipe.find(filtro).populate('membros', 'nome email fotoPerfil');
    res.json(await assinarFotosMembrosEquipes(equipes));
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao listar equipes do usuario' });
  }
};

exports.obterEquipe = async (req, res) => {
  try {
    const equipe = await Equipe.findById(req.params.id).populate('membros', 'nome email fotoPerfil');
    if (!equipe) return res.status(404).json({ erro: 'Equipe não encontrada' });
    res.json(await assinarFotosMembrosEquipe(equipe));
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar equipe' });
  }
};

exports.editarEquipe = async (req, res) => {
  try {
    const { nome, membros } = req.body;

    const membrosArray = Array.isArray(membros) ? membros : [];
    const membrosUnicos = [...new Set(membrosArray.map((id) => String(id).trim()))].filter(Boolean);

    const membrosInvalidos = membrosUnicos.filter((id) => !mongoose.isValidObjectId(id));
    if (membrosInvalidos.length > 0) {
      return res.status(400).json({ erro: 'Existem membros com identificadores inválidos' });
    }

    const usuarios = await User.find({ _id: { $in: membrosUnicos }, tipo: 'user' }).select('_id');
    if (usuarios.length !== membrosUnicos.length) {
      return res.status(400).json({ erro: 'Alguns membros não são usuarios válidos' });
    }

    const equipeAtualizada = await Equipe.findByIdAndUpdate(
      req.params.id,
      { nome, membros: membrosUnicos },
      { new: true }
    ).populate('membros', 'nome email fotoPerfil');

    if (!equipeAtualizada) {
      return res.status(404).json({ erro: 'Equipe não encontrada' });
    }

    res.json(await assinarFotosMembrosEquipe(equipeAtualizada));
  } catch (err) {
    console.error('Erro ao editar equipe:', err.message);
    res.status(500).json({ erro: 'Erro ao editar equipe', detalhe: err.message });
  }
};


exports.excluirEquipe = async (req, res) => {
  try {
    await Equipe.findByIdAndDelete(req.params.id);
    res.json({ msg: 'Equipe excluída com sucesso' });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao excluir equipe' });
  }
};

exports.getMembrosDaEquipe = async (req, res) => {
  try {
    const equipe = await Equipe.findById(req.params.id).populate("membros", "nome fotoPerfil");
    if (!equipe) return res.status(404).json({ erro: "Equipe não encontrada" });
    const equipeAssinada = await assinarFotosMembrosEquipe(equipe);
    res.json(equipeAssinada.membros);
  } catch (err) {
    res.status(500).json({ erro: "Erro ao buscar membros" });
  }
};

exports.getMessages = async (req, res) => {
  try {
    const messages = await Message.find({ equipe: req.params.id })
      .populate('user', 'nome fotoPerfil')
      .sort({ createdAt: 1 });
      
    res.json(await Promise.all(messages.map(assinarFotoUsuarioMensagem)));
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar histórico de mensagens' });
  }
};

exports.addNovoUsuario = async (req, res) => {
  try {
    const { equipeId, userId } = req.body;
    const equipe = await Equipe.findById(equipeId);
    if (!equipe) return res.status(404).json({ erro: 'Equipe não encontrada' });

    const usuario = await User.findById(userId);
    if (!usuario) return res.status(404).json({ erro: 'Usuario não encontrado' });

    if (equipe.membros.includes(userId)) {
      return res.status(400).json({ erro: 'Usuario já é membro da equipe' });
    }

    equipe.membros.push(userId);
    await equipe.save();
    notificarEntradaEquipe(usuario.nome, equipe.nome);

    res.status(201).json(equipe);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao adicionar usuário à equipe' });
  }
};



