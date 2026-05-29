import React, { useEffect, useState } from 'react';
import apiClient from '../../config/apiClient';
import { useNavigate } from 'react-router-dom';
import Sidebar from '../../components/layout/Sidebar';
import '../../styles/pages/user/BacklogUser.css';

const BacklogUser = () => {
  const [tarefas, setTarefas] = useState([]);
  const [mensagem, setMensagem] = useState('');
  const [tipoMensagem, setTipoMensagem] = useState('sucesso');
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  /*const getAuthConfig = () => ({
    headers: { Authorization: `Bearer ${localStorage.getItem('token')}` },
  });*/

  const carregarBacklog = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get('/tarefas/backlog');
      setTarefas(response.data || []);
    } catch (error) {
      setTipoMensagem('erro');
      setMensagem('Erro ao carregar backlog');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    carregarBacklog();
  }, []);

  const formatarData = (data) => {
    if (!data) return '-';
    return new Date(data).toLocaleDateString();
  };

  return (
    <div className="backlog-page">
      <Sidebar />

      <main className="backlog-content">
        <div className="backlog-container">
          <h2>Backlog de Tarefas</h2>
          <p className="backlog-subtitle">
            Tarefas da sua equipe que ainda não possuem responsável.
          </p>

          {mensagem && <div className={`mensagem ${tipoMensagem}`}>{mensagem}</div>}

          {loading ? (
            <div className="backlog-empty">Carregando backlog...</div>
          ) : tarefas.length === 0 ? (
            <div className="backlog-empty">Nenhuma tarefa pendente no backlog.</div>
          ) : (
            <div className="backlog-list">
              {tarefas.map((tarefa) => (
                <button
                  key={tarefa._id}
                  type="button"
                  className="backlog-item"
                  onClick={() => navigate(`/backlog/${tarefa._id}`)}
                >
                  <div className="backlog-item-main">
                    <h3>{tarefa.descricao || 'Sem título'}</h3>
                    <p className="backlog-item-meta">
                      Equipe: {tarefa.equipe?.nome || 'Não informada'} • Entrega: {formatarData(tarefa.dataEntrega)}
                    </p>
                    {tarefa.detalhes && (
                      <p className="backlog-item-preview">{tarefa.detalhes}</p>
                    )}
                  </div>
                  <span className="backlog-item-action">Ver detalhes</span>
                </button>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
};

export default BacklogUser;
