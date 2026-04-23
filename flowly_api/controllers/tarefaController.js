const Tarefa = require('../models/Tarefa');
const User = require('../models/User');
const Equipe = require('../models/Equipe');
const Comment = require('../models/Comment');
const ActivityLog = require('../models/ActivityLog');
const logActivity = require('../utils/activityLogger');

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
  } catch(err) {
    res.status(500).json({ erro: 'Erro ao adicionar comentário', detalhe: err.message });
  }
};

// ALL: add subtask
exports.adicionarSubtarefa = async (req, res) => {
  try {
    const { descricao } = req.body;
    if (!descricao) return res.status(400).json({ erro: 'Obrigatório fornecer descrição' });

    const tarefa = await Tarefa.findById(req.params.id);
    if(!tarefa) return res.status(404).json({ erro: 'Tarefa não encontrada' });

    tarefa.subtarefas.push({ descricao, concluida: false });
    await tarefa.save();

    await logActivity('nova_subtarefa', `Subtarefa '${descricao}' adicionada`, req.user.id, req.params.id);
    res.status(201).json(tarefa);
  } catch(err) {
    res.status(500).json({erro: 'Erro ao adicionar subtarefa'});
  }
};

// ALL: toggle subtask
exports.toggleSubtarefa = async (req, res) => {
  try {
    const { subId } = req.params;
    const tarefa = await Tarefa.findById(req.params.id);
    if(!tarefa) return res.status(404).json({ erro: 'Tarefa não encontrada' });

    const sub = tarefa.subtarefas.id(subId);
    if (!sub) return res.status(404).json({ erro: 'Subtarefa não encontrada' });

    sub.concluida = !sub.concluida;
    await tarefa.save();

    res.json(tarefa);
  } catch(err) {
    res.status(500).json({erro: 'Erro ao alterar subtarefa'});
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

    const equipe = await Equipe.findById(tarefa.equipe).select('membros');
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

    const tarefa = await Tarefa.findOne({ _id: req.params.id, user: req.user.id });

    if (!tarefa) {
      return res.status(403).json({ erro: 'Você não pode editar essa tarefa' });
    }

    tarefa.status = status;
    await tarefa.save();

    await logActivity('atualizacao_status', `Status alterado para ${status}`, req.user.id, tarefa._id);

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
    
    if(!tarefa) return res.status(403).json({ erro: 'Acesso negado à tarefa' });

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

    const { originalname, filename, size } = req.file;

    // A url do arquivo pra acesso público via nosso app.js
    const fileUrl = `/uploads/${filename}`;

    const novoAnexo = {
      url: fileUrl,
      nomeOriginal: originalname,
      mimetype: req.file.mimetype,
      size,
    };

    tarefa.anexos.push(novoAnexo);
    await tarefa.save();

    await logActivity('novo_anexo', `Arquivo anexado: ${originalname}`, req.user.id, tarefa._id);

    res.status(201).json({ msg: 'Anexo adicionado com sucesso', anexo: novoAnexo });
  } catch (err) {
    res.status(500).json({ erro: 'Erro no upload de anexo', detalhe: err.message });
  }
};
