import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useNavigate, useParams } from 'react-router-dom';
import Sidebar from '../../components/layout/Sidebar';
import '../../styles/pages/user/BacklogTaskDetailUser.css';

const BacklogTaskDetailUser = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const [loading, setLoading] = useState(true);
  const [atribuindo, setAtribuindo] = useState(false);
  const [mensagem, setMensagem] = useState('');
  const [tipoMensagem, setTipoMensagem] = useState('sucesso');
  const [tarefa, setTarefa] = useState(null);

  const getAuthConfig = () => ({
    headers: { Authorization: `Bearer ${localStorage.getItem('token')}` },
  });

  const carregarDetalhes = async () => {
    try {
      setLoading(true);
      const response = await axios.get(
        `http://localhost:5000/api/tarefas/${id}/detalhes`,
        getAuthConfig(),
      );
      const tarefaApi = response?.data?.tarefa || null;
      if (!tarefaApi) {
        setTipoMensagem('erro');
        setMensagem('Tarefa não encontrada.');
        return;
      }
      setTarefa(tarefaApi);
    } catch (error) {
      const erroApi =
        error?.response?.data?.erro ||
        error?.response?.data?.error ||
        'Erro ao carregar detalhes da tarefa';
      setTipoMensagem('erro');
      setMensagem(erroApi);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (id) {
      carregarDetalhes();
    }
  }, [id]);

  const atribuirParaMim = async () => {
    if (!tarefa?._id || atribuindo) {
      return;
    }

    try {
      setAtribuindo(true);
      await axios.put(
        `http://localhost:5000/api/tarefas/${tarefa._id}/atribuir-para-mim`,
        {},
        getAuthConfig(),
      );

      setTipoMensagem('sucesso');
      setMensagem('Tarefa atribuída para você com sucesso! Redirecionando para o Kanban...');
      setTimeout(() => {
        navigate('/minhas-tarefas');
      }, 900);
    } catch (error) {
      const erroApi =
        error?.response?.data?.erro ||
        error?.response?.data?.error ||
        'Não foi possível atribuir a tarefa';
      setTipoMensagem('erro');
      setMensagem(erroApi);
    } finally {
      setAtribuindo(false);
    }
  };

  const formatarData = (data) => {
    if (!data) return '-';
    return new Date(data).toLocaleDateString();
  };

  return (
    <div className="backlog-detail-page">
      <Sidebar />

      <main className="backlog-detail-content">
        <div className="backlog-detail-container">
          <div className="backlog-detail-topbar">
            <button type="button" className="backlog-back-btn" onClick={() => navigate('/backlog')}>
              Voltar ao backlog
            </button>
          </div>

          {mensagem && <div className={`mensagem ${tipoMensagem}`}>{mensagem}</div>}

          {loading ? (
            <div className="backlog-detail-empty">Carregando tarefa...</div>
          ) : !tarefa ? (
            <div className="backlog-detail-empty">Não foi possível carregar esta tarefa.</div>
          ) : (
            <section className="backlog-detail-card">
              <header>
                <h2>{tarefa.descricao || 'Sem título'}</h2>
                <p>
                  Equipe: {tarefa.equipe?.nome || 'Não informada'} • Entrega: {formatarData(tarefa.dataEntrega)}
                </p>
              </header>

              <div className="backlog-detail-grid">
                <div>
                  <span className="label">Status</span>
                  <strong>{tarefa.status || 'pendente'}</strong>
                </div>
                <div>
                  <span className="label">Urgência</span>
                  <strong>{tarefa.urgencia || 'baixa'}</strong>
                </div>
                <div>
                  <span className="label">Responsável atual</span>
                  <strong>{tarefa.user?.nome || 'Sem responsável'}</strong>
                </div>
              </div>

              <article className="backlog-detail-description">
                <h3>Descrição</h3>
                <p>{tarefa.detalhes || 'Sem descrição detalhada.'}</p>
              </article>

              <footer className="backlog-detail-actions">
                <button
                  type="button"
                  className="btn-assign"
                  onClick={atribuirParaMim}
                  disabled={atribuindo || !!tarefa.user}
                >
                  {tarefa.user
                    ? 'Tarefa já possui responsável'
                    : atribuindo
                      ? 'Atribuindo...'
                      : 'Atribuir para mim'}
                </button>
              </footer>
            </section>
          )}
        </div>
      </main>
    </div>
  );
};

export default BacklogTaskDetailUser;
