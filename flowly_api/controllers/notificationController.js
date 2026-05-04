const Notification = require('../models/Notification');

exports.listarNotificacoes = async (req, res) => {
  try {
    const { unread } = req.query;
    const filtro = { user: req.user.id };

    if (unread === 'true') {
      filtro.lida = false;
    }

    const notificacoes = await Notification.find(filtro)
      .sort({ createdAt: -1 })
      .limit(100);

    res.json(notificacoes);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao buscar notificações' });
  }
};

exports.contarNaoLidas = async (req, res) => {
  try {
    const count = await Notification.countDocuments({ user: req.user.id, lida: false });
    res.json({ count });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao contar notificações' });
  }
};

exports.marcarComoLida = async (req, res) => {
  try {
    const notificacao = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user.id },
      { lida: true },
      { new: true }
    );

    if (!notificacao) {
      return res.status(404).json({ erro: 'Notificação não encontrada' });
    }

    res.json(notificacao);
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao atualizar notificação' });
  }
};

exports.marcarTodasComoLidas = async (req, res) => {
  try {
    await Notification.updateMany(
      { user: req.user.id, lida: false },
      { lida: true }
    );

    res.json({ msg: 'Notificações marcadas como lidas' });
  } catch (err) {
    res.status(500).json({ erro: 'Erro ao atualizar notificações' });
  }
};