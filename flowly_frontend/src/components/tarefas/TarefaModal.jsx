import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { authUtils } from '../../config/authUtils';
import { formatarStatus } from '../../config/statusUtils';
import '../../styles/components/TarefaModal.css';

const TarefaModal = ({ tarefaId, onClose }) => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('detalhes'); // detalhes, subtarefas, anexos, comentarios, logs
  const [novoComentario, setNovoComentario] = useState('');
  const [novaSubtarefa, setNovaSubtarefa] = useState('');
  const [arquivo, setArquivo] = useState(null);
  const [uploading, setUploading] = useState(false);

  const getAuthConfig = () => ({
    headers: { Authorization: `Bearer ${authUtils.getToken()}` }
  });

  const carregarDetalhes = async () => {
    try {
      const res = await axios.get(`http://localhost:5000/api/tarefas/${tarefaId}/detalhes`, getAuthConfig());
      setData(res.data);
      setLoading(false);
    } catch (err) {
      console.error(err);
      setLoading(false);
    }
  };

  useEffect(() => {
    carregarDetalhes();
  }, [tarefaId]);

  const toggleSub = async (subId) => {
    try {
      await axios.put(`http://localhost:5000/api/tarefas/${tarefaId}/subtarefas/${subId}`, {}, getAuthConfig());
      carregarDetalhes(); // Recarrega
    } catch (err) {
      console.error(err);
    }
  };

  const addSubtarefa = async () => {
    if(!novaSubtarefa.trim()) return;
    try {
      await axios.post(`http://localhost:5000/api/tarefas/${tarefaId}/subtarefas`, { descricao: novaSubtarefa }, getAuthConfig());
      setNovaSubtarefa('');
      carregarDetalhes();
    } catch (err) {
      console.error(err);
    }
  };

  const addComentario = async () => {
    if(!novoComentario.trim()) return;
    try {
      await axios.post(`http://localhost:5000/api/tarefas/${tarefaId}/comentarios`, { texto: novoComentario }, getAuthConfig());
      setNovoComentario('');
      carregarDetalhes();
    } catch (err) {
      console.error(err);
    }
  };

  const fazerUpload = async () => {
    if (!arquivo) return;
    setUploading(true);
    try {
      const formData = new FormData();
      formData.append('file', arquivo);

      await axios.post(`http://localhost:5000/api/tarefas/${tarefaId}/anexos`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
          Authorization: `Bearer ${authUtils.getToken()}`
        }
      });
      setArquivo(null);
      carregarDetalhes();
    } catch (err) {
      console.error(err);
      alert(err?.response?.data?.erro || 'Falha ao enviar arquivo');
    } finally {
      setUploading(false);
    }
  };

  if (loading) return <div className="modal-overlay"><div className="modal-content">Carregando detalhes...</div></div>;
  if (!data || !data.tarefa) return null;

  const { tarefa, comentarios, logs } = data;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{tarefa.descricao}</h2>
          <button className="close-btn" onClick={onClose}>✕</button>
        </div>

        <div className="modal-tabs">
          <button className={activeTab === 'detalhes' ? 'active' : ''} onClick={() => setActiveTab('detalhes')}>Resumo</button>
          <button className={activeTab === 'subtarefas' ? 'active' : ''} onClick={() => setActiveTab('subtarefas')}>Subtarefas ({tarefa.subtarefas?.length || 0})</button>
          <button className={activeTab === 'anexos' ? 'active' : ''} onClick={() => setActiveTab('anexos')}>Anexos ({tarefa.anexos?.length || 0})</button>
          <button className={activeTab === 'comentarios' ? 'active' : ''} onClick={() => setActiveTab('comentarios')}>Comentários ({comentarios.length})</button>
          <button className={activeTab === 'logs' ? 'active' : ''} onClick={() => setActiveTab('logs')}>Histórico</button>
        </div>

        <div className="modal-body">
          {activeTab === 'detalhes' && (
            <div className="tab-detalhes">
              <p><strong>Detalhes:</strong> {tarefa.detalhes || 'Sem detalhes'}</p>
              <p><strong>Status:</strong> {formatarStatus(tarefa.status)}</p>
              <p><strong>Urgência:</strong> {tarefa.urgencia}</p>
              <p><strong>Prazo:</strong> {tarefa.dataEntrega ? new Date(tarefa.dataEntrega).toLocaleDateString() : 'Não definido'}</p>
              <p><strong>Tempo Gasto:</strong> {tarefa.tempoGasto || 0} min {tarefa.cronometroAtivo ? '(Ativo)' : ''}</p>
              {tarefa.tags && tarefa.tags.length > 0 && (
                <div className="tags-list">
                  {tarefa.tags.map((tag, i) => <span key={i} className="tag-badge">#{tag}</span>)}
                </div>
              )}
            </div>
          )}

          {activeTab === 'subtarefas' && (
            <div className="tab-subtarefas">
              <div className="subtarefas-list">
                {tarefa.subtarefas?.map(sub => (
                  <label key={sub._id} className="subtarefa-item">
                    <input 
                      type="checkbox" 
                      checked={sub.concluida} 
                      onChange={() => toggleSub(sub._id)} 
                    />
                    <span className={sub.concluida ? 'concluida' : ''}>{sub.descricao}</span>
                  </label>
                ))}
                {(!tarefa.subtarefas || tarefa.subtarefas.length === 0) && <p>Nenhuma subtarefa.</p>}
              </div>
              <div className="add-form">
                <input 
                  type="text" 
                  placeholder="Nova checklist..." 
                  value={novaSubtarefa}
                  onChange={e => setNovaSubtarefa(e.target.value)} 
                />
                <button onClick={addSubtarefa}>Add</button>
              </div>
            </div>
          )}

          {activeTab === 'comentarios' && (
            <div className="tab-comentarios">
              <div className="comentarios-list">
                {comentarios.map(c => (
                  <div key={c._id} className="comentario-item">
                    <div className="comentario-header">
                      <strong>{c.user?.nome}</strong>
                      <span>{new Date(c.createdAt).toLocaleString()}</span>
                    </div>
                    <div className="comentario-body">{c.texto}</div>
                  </div>
                ))}
                {comentarios.length === 0 && <p>Nenhum comentário na tarefa.</p>}
              </div>
              <div className="add-form">
                <textarea 
                  placeholder="Seu comentário..." 
                  value={novoComentario}
                  onChange={e => setNovoComentario(e.target.value)}
                />
                <button onClick={addComentario}>Comentar</button>
              </div>
            </div>
          )}

          {activeTab === 'anexos' && (
            <div className="tab-anexos">
              <div className="anexos-list">
                {tarefa.anexos?.map((anexo, i) => (
                  <div key={i} className="anexo-item">
                    📄 <a href={`http://localhost:5000${anexo.url}`} target="_blank" rel="noreferrer">{anexo.nomeOriginal || anexo.nome || 'Arquivo'}</a>
                    <span className="anexo-size">({Math.round((anexo.size || anexo.tamanho || 0) / 1024)} KB)</span>
                  </div>
                ))}
                {(!tarefa.anexos || tarefa.anexos.length === 0) && <p>Nenhum anexo na tarefa.</p>}
              </div>
              <div className="upload-form">
                <input 
                  type="file" 
                  onChange={e => setArquivo(e.target.files[0])} 
                  disabled={uploading}
                />
                <button 
                  onClick={fazerUpload} 
                  disabled={!arquivo || uploading}
                >
                  {uploading ? 'Enviando...' : 'Fazer Upload'}
                </button>
              </div>
            </div>
          )}

          {activeTab === 'logs' && (
            <div className="tab-logs">
              <ul className="logs-list">
                {logs.map(log => (
                  <li key={log._id}>
                    <span className="log-time">{new Date(log.createdAt).toLocaleString()}</span>
                    <span className="log-user">{log.user?.nome}</span>
                    <span className="log-action">[{log.tipoAcao}]</span>
                    <span className="log-detail">{log.detalhes}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default TarefaModal;
