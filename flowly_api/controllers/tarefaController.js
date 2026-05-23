const Tarefa = require('../models/Tarefa');
const User = require('../models/User');
const Equipe = require('../models/Equipe');
const Comment = require('../models/Comment');
const ActivityLog = require('../models/ActivityLog');
const logActivity = require('../utils/activityLogger');
const { notifyUsers } = require('../utils/notificationService');
const bucket = require('../services/storage');


// ADMIN creates task for user
exports.criarTarefa = async (req, res) => {
  try {
    const { descricao, detalhes, dataEntrega, user, equipe, tempoEstimado, urgencia, tags, subtarefas } = req.body;
    if (!equipe) return res.status(400).json({ erro: 'Equipe é obrigatória' });

    const equipeDoc = await Equipe.findById(equipe).select('membros nome');
    if (!equipeDoc) {
      return res.status(400).json({ erro: 'Equipe inválida' });
    }

    let usuario = null;
    let userId = null;
    if (user && String(user).trim()) {
      userId = String(user).trim();
    }

    if (userId) {
      usuario = await User.findById(userId);
      if (!usuario || usuario.tipo !== 'user') {
        return res.status(400).json({ erro: 'User inválido' });
      }
      const pertenceEquipe = equipeDoc.membros.some(
        (membroId) => String(membroId) === String(usuario._id),
      );
      if (!pertenceEquipe) {
        return res.status(400).json({ erro: 'Usuário não pertence à equipe selecionada' });
      }
    }

    const tarefa = new Tarefa({
      descricao,
      detalhes,
      dataEntrega,
      createdBy: req.user.id,
      user: userId,
      equipe,
      tempoEstimado,
      urgencia,
      tags: tags || [],
      subtarefas: subtarefas || []
    });
    await tarefa.save();

    const descricaoCriacao = usuario
      ? `Tarefa criada e atribuída a ${usuario.nome}`
      : 'Tarefa criada sem responsável e enviada ao backlog';
    await logActivity('criacao', descricaoCriacao, req.user.id, tarefa._id);

    res.status(201).json(tarefa);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao criar tarefa', detalhe: err.message });
  }
};

// ADMIN: list tasks (or filter by user/team)
exports.listarTarefas = async (req, res) => {
  try {
    const { user, equipe } = req.query;
    const filtro = {};
    if (user) filtro.user = user;
    if (equipe) filtro.equipe = equipe;

    const tarefas = await Tarefa.find(filtro)
      .populate('user', 'nome')
      .populate('equipe', 'nome')
      .sort({ urgencia: -1, dataEntrega: 1 });
    res.json(tarefas);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao listar tarefas' });
  }
};

// ADMIN: editar tarefa
exports.editarTarefa = async (req, res) => {
  try {
    const { descricao, detalhes, dataEntrega, user, equipe, tempoEstimado, urgencia, tags } = req.body;

    const tarefaAtual = await Tarefa.findById(req.params.id);
    if (!tarefaAtual) {
      return res.status(404).json({ erro: 'Tarefa não encontrada' });
    }

    const equipeAlvo = equipe || tarefaAtual.equipe;
    const equipeDoc = await Equipe.findById(equipeAlvo).select('membros');
    if (!equipeDoc) {
      return res.status(400).json({ erro: 'Equipe inválida' });
    }

    let userAlvo = user;
    if (userAlvo === '' || userAlvo === null) {
      userAlvo = null;
    }

    if (userAlvo) {
      const usuario = await User.findById(userAlvo);
      if (!usuario || usuario.tipo !== 'user') {
        return res.status(400).json({ erro: 'User inválido' });
      }
      const pertenceEquipe = equipeDoc.membros.some(
        (membroId) => String(membroId) === String(usuario._id),
      );
      if (!pertenceEquipe) {
        return res.status(400).json({ erro: 'Usuário não pertence à equipe selecionada' });
      }
    }

    const dadosAtualizacao = {
      descricao,
      detalhes,
      dataEntrega,
      equipe,
      tempoEstimado,
      urgencia,
      tags,
    };
    if (user !== undefined) {
      dadosAtualizacao.user = userAlvo;
    }

    const tarefaAtualizada = await Tarefa.findByIdAndUpdate(
      req.params.id,
      dadosAtualizacao,
      { new: true }
    );

    await logActivity('atualizacao_geral', 'Detalhes da tarefa foram atualizados', req.user.id, tarefaAtualizada._id);
    res.json(tarefaAtualizada);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao editar tarefa' });
  }
};

// ADMIN: excluir
exports.excluirTarefa = async (req, res) => {
  try {
    await Tarefa.findByIdAndDelete(req.params.id);
    res.json({ msg: 'Tarefa excluída' });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao excluir tarefa' });
  }
};

// ALL: get task details with comments and logs
exports.detalhesTarefa = async (req, res) => {
  try {
    const tarefa = await Tarefa.findById(req.params.id)
      .populate('user', 'nome')
      .populate('equipe', 'nome');

    if (!tarefa) return res.status(404).json({ erro: 'Tarefa não encontrada' });

    const comentarios = await Comment.find({ tarefa: req.params.id }).populate('user', 'nome').sort({ createdAt: 1 });
    const logs = await ActivityLog.find({ tarefa: req.params.id }).populate('user', 'nome').sort({ createdAt: -1 });

    res.json({ tarefa, comentarios, logs });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar detalhes da tarefa', detalhe: err.message });
  }
};

// ALL: add comment
exports.adicionarComentario = async (req, res) => {
  try {
    const { texto } = req.body;
    if (!texto) return res.status(400).json({ erro: 'Texto do comentário vazio' });

    const comentario = new Comment({ texto, user: req.user.id, tarefa: req.params.id });
    await comentario.save();

    await logActivity('comentario', 'Comentário adicionado', req.user.id, req.params.id);

    const populateComentario = await Comment.findById(comentario._id).populate('user', 'nome');
    res.status(201).json(populateComentario);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao adicionar comentário', detalhe: err.message });
  }
};

// ALL: add subtask
exports.adicionarSubtarefa = async (req, res) => {
  try {
    const { descricao } = req.body;
    if (!descricao) return res.status(400).json({ erro: 'Obrigatório fornecer descrição' });

    const tarefa = await Tarefa.findById(req.params.id);
    if (!tarefa) return res.status(404).json({ erro: 'Tarefa não encontrada' });

    tarefa.subtarefas.push({ descricao, concluida: false });
    await tarefa.save();

    await logActivity('nova_subtarefa', `Subtarefa '${descricao}' adicionada`, req.user.id, req.params.id);
    res.status(201).json(tarefa);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao adicionar subtarefa' });
  }
};

// ALL: toggle subtask
exports.toggleSubtarefa = async (req, res) => {
  try {
    const { subId } = req.params;
    const tarefa = await Tarefa.findById(req.params.id);
    if (!tarefa) return res.status(404).json({ erro: 'Tarefa não encontrada' });

    const sub = tarefa.subtarefas.id(subId);
    if (!sub) return res.status(404).json({ erro: 'Subtarefa não encontrada' });

    sub.concluida = !sub.concluida;
    await tarefa.save();

    res.json(tarefa);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao alterar subtarefa' });
  }
};

// USER: view their own tasks
exports.minhasTarefas = async (req, res) => {
  try {
    const tarefas = await Tarefa.find({ user: req.user.id })
      .populate('equipe', 'nome');
    res.json(tarefas);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar suas tarefas' });
  }
};

// USER: backlog de tarefas sem responsável (apenas equipes do usuário)
exports.listarBacklog = async (req, res) => {
  try {
    const minhasEquipes = await Equipe.find({ membros: req.user.id }).select('_id');
    const equipeIds = minhasEquipes.map((equipe) => equipe._id);

    if (equipeIds.length === 0) {
      return res.json([]);
    }

    const tarefas = await Tarefa.find({
      equipe: { $in: equipeIds },
      $or: [{ user: null }, { user: { $exists: false } }],
    })
      .populate('equipe', 'nome')
      .sort({ urgencia: -1, dataEntrega: 1 });

    res.json(tarefas);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar backlog', detalhe: err.message });
  }
};

// USER: atribuir tarefa do backlog para si mesmo
exports.atribuirParaMim = async (req, res) => {
  try {
    const tarefa = await Tarefa.findById(req.params.id);
    if (!tarefa) {
      return res.status(404).json({ erro: 'Tarefa não encontrada' });
    }

    if (tarefa.user) {
      return res.status(409).json({ erro: 'Esta tarefa já possui responsável' });
    }

    const equipe = await Equipe.findById(tarefa.equipe).select('membros createdBy nome');
    if (!equipe) {
      return res.status(400).json({ erro: 'Equipe da tarefa não encontrada' });
    }

    const pertenceEquipe = equipe.membros.some(
      (membroId) => String(membroId) === String(req.user.id),
    );

    if (!pertenceEquipe) {
      return res.status(403).json({ erro: 'Você não pertence à equipe desta tarefa' });
    }

    tarefa.user = req.user.id;
    await tarefa.save();

    await logActivity(
      'atualizacao_geral',
      'Tarefa atribuída automaticamente para o colaborador',
      req.user.id,
      tarefa._id,
    );

    const notificarAdmin = tarefa.createdBy || equipe.createdBy;
    if (notificarAdmin && String(notificarAdmin) !== String(req.user.id)) {
      const usuario = await User.findById(req.user.id).select('nome');
      await notifyUsers({
        userIds: [notificarAdmin],
        texto: `${usuario?.nome || 'Um colaborador'} pegou a tarefa "${tarefa.descricao}" do backlog`,
        tipo: 'task',
        origemId: tarefa._id,
        metadata: { tarefaId: tarefa._id, acao: 'atribuir_para_mim' },
      });
    }

    const tarefaAtualizada = await Tarefa.findById(tarefa._id)
      .populate('user', 'nome')
      .populate('equipe', 'nome');

    res.json({ msg: 'Tarefa atribuída com sucesso', tarefa: tarefaAtualizada });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao atribuir tarefa', detalhe: err.message });
  }
};

// USER: update task status
exports.atualizarStatusUser = async (req, res) => {
  try {
    const { status } = req.body;

    if (!status || !["pendente", "em_andamento", "concluido"].includes(status)) {
      return res.status(400).json({ erro: "Status inválido" });
    }

    const tarefa = await Tarefa.findOne({ _id: req.params.id, user: req.user.id }).populate('equipe', 'createdBy nome');

    if (!tarefa) {
      return res.status(403).json({ erro: 'Você não pode editar essa tarefa' });
    }

    tarefa.status = status;
    await tarefa.save();

    await logActivity('atualizacao_status', `Status alterado para ${status}`, req.user.id, tarefa._id);

    const notificarAdmin = tarefa.createdBy || tarefa.equipe?.createdBy;
    if (notificarAdmin && String(notificarAdmin) !== String(req.user.id)) {
      const usuario = await User.findById(req.user.id).select('nome');
      const statusLegivel = status === 'em_andamento'
        ? 'em andamento'
        : status === 'concluido'
          ? 'concluída'
          : status;

      await notifyUsers({
        userIds: [notificarAdmin],
        texto: `${usuario?.nome || 'Um colaborador'} marcou a tarefa "${tarefa.descricao}" como ${statusLegivel}`,
        tipo: 'task',
        origemId: tarefa._id,
        metadata: { tarefaId: tarefa._id, status },
      });
    }

    res.json({ msg: 'Status atualizado com sucesso', tarefa });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao atualizar status', detalhe: err.message });
  }
};

// USER: controlar cronômetro
exports.controlarCronometro = async (req, res) => {
  try {
    const { acao } = req.body; // 'iniciar' ou 'pausar'
    const tarefa = await Tarefa.findOne({ _id: req.params.id, user: req.user.id });

    if (!tarefa) return res.status(403).json({ erro: 'Acesso negado à tarefa' });

    if (acao === 'iniciar') {
      if (tarefa.cronometroAtivo) {
        return res.status(400).json({ erro: 'Cronômetro já está ativo' });
      }
      tarefa.cronometroAtivo = true;
      tarefa.ultimaAtualizacaoCronometro = new Date();
      await logActivity('cronometro_iniciado', `Cronômetro iniciado`, req.user.id, tarefa._id);
    } else if (acao === 'pausar') {
      if (!tarefa.cronometroAtivo) {
        return res.status(400).json({ erro: 'Cronômetro já está pausado' });
      }
      const tempoDecorrido = Math.floor((new Date() - tarefa.ultimaAtualizacaoCronometro) / 60000); // converte para minutos
      tarefa.tempoGasto += tempoDecorrido;
      tarefa.cronometroAtivo = false;

      // Verifica se o tempo estimado foi excedido
      if (tarefa.tempoEstimado && tarefa.tempoGasto > tarefa.tempoEstimado) {
        tarefa.tempoExcedido = true;
      }
      await logActivity('cronometro_pausado', `Cronômetro pausado. +${tempoDecorrido} mins`, req.user.id, tarefa._id);
    }

    await tarefa.save();
    res.json({
      msg: `Cronômetro ${acao}do com sucesso`,
      tarefa,
      tempoExcedido: tarefa.tempoExcedido
    });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao controlar cronômetro' });
  }
};

// ALL: Upload de anexos
exports.adicionarAnexo = async (req, res) => {
  try {
    const tarefa = await Tarefa.findById(req.params.id);
    if (!tarefa) return res.status(404).json({ erro: 'Tarefa não encontrada' });

    if (!req.file) {
      return res.status(400).json({ erro: 'Nenhum arquivo enviado' });
    }

    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);

    const extension = path.extname(req.file.originalname);
    const filename = `tarefas/${tarefa._id}/${uniqueSuffix}${extension}`;

    const blob = bucket.file(filename);

    const blobStream = blob.createWriteStream({
      resumable: false,
      metadata: {
        contentType: req.file.mimetype
      }
    });

    blobStream.on('error', (err) => {
      console.error('Erro ao fazer upload para o Google Cloud Storage:', err);
      if (!res.headersSent) {
        res.status(500).json({ erro: 'Erro ao fazer upload do anexo' });
      }
    });

    blobStream.on('finish', async () => {
      try {
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${blob.name}`;

        const novoAnexo = {
          url: publicUrl,
          nomeOriginal: req.file.originalname,
          mimetype: req.file.mimetype,
          size: req.file.size
        };

        tarefa.anexos.push(novoAnexo);
        await tarefa.save();

        await logActivity(
          'novo_anexo',
          `Arquivo anexado: ${req.file.originalname}`,
          req.user.id,
          tarefa._id
        );

        res.status(201).json({
          msg: 'Anexo adicionado com sucesso',
          anexo: novoAnexo
        });
      } catch (err) {
        console.error('Erro ao processar anexo após upload:', err);
        if (!res.headersSent) {
          res.status(500).json({ erro: 'Erro ao processar anexo', detalhe: err.message });
        }
      }
    });

    blobStream.end(req.file.buffer);
  } catch (err) {
    res.status(500).json({ erro: 'Erro no upload de anexo', detalhe: err.message });
  }
};
