import React, { useState, useEffect } from 'react';
import apiClient from '../../config/apiClient';
//import { authUtils } from '../../config/authUtils';
import '../../styles/components/FloatingTimer.css';

const FloatingTimer = () => {
  const [tarefasAtivas, setTarefasAtivas] = useState([]);
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    const fetchAtivas = async () => {
      try {
        const res = await apiClient.get('/tarefas/minhas');
        const ativas = res.data.filter(t => t.cronometroAtivo);
        setTarefasAtivas(ativas);
      } catch (err) {
        console.error('Erro ao buscar tarefas ativas', err);
      }
    };

    fetchAtivas();
        
    // Tick de 1 minuto para atualização da tela local
    const intervalTicker = setInterval(() => {
      setNow(Date.now());
    }, 60000); 
        
    // Polling do backend para garantir consistencia com o server
    const intervalPoll = setInterval(fetchAtivas, 60000 * 2);

    return () => { 
      clearInterval(intervalTicker); 
      clearInterval(intervalPoll); 
    };
  }, []);

  if (tarefasAtivas.length === 0) return null;

  return (
    <div className="floating-timer-container">
      {tarefasAtivas.map(t => {
        const startedAt = new Date(t.ultimaAtualizacaoCronometro).getTime();
        const minsThisSession = Math.max(0, Math.floor((now - startedAt) / 60000));
        const totalMins = (t.tempoGasto || 0) + minsThisSession;

        return (
          <div key={t._id} className={`floating-timer-chip ${t.tempoExcedido || (t.tempoEstimado && totalMins > t.tempoEstimado) ? 'danger' : ''}`}>
            ⏱️ <strong>{t.descricao.length > 20 ? t.descricao.substring(0, 20)+'...' : t.descricao}</strong> 
            <span className="time-badge">{totalMins} min</span>
          </div>
        );
      })}
    </div>
  );
};

export default FloatingTimer;
