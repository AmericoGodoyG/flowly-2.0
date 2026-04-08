const ActivityLog = require('../models/ActivityLog');

const logActivity = async (tipoAcao, detalhes, user, tarefa) => {
  try {
    const log = new ActivityLog({
      tipoAcao,
      detalhes,
      user,
      tarefa
    });
    await log.save();
  } catch (error) {
    console.error('Erro ao registrar log de atividade:', error);
  }
};

module.exports = logActivity;
