import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import axios from 'axios';
import { DragDropContext, Droppable, Draggable } from '@hello-pangea/dnd';
import Sidebar from '../../components/layout/Sidebar';
import TarefaModal from '../../components/tarefas/TarefaModal';
import '../../styles/pages/user/TarefasUser.css';

const TarefasUser = () => {
  const [tarefas, setTarefas] = useState([]);
  const [mensagem, setMensagem] = useState('');
  const [tarefaInspecionada, setTarefaInspecionada] = useState(null);

  useEffect(() => {
    carregarTarefas();
  }, []);

  const getAuthConfig = () => {
    return {
      headers: { Authorization: `Bearer ${localStorage.getItem('token')}` }
    };
  };

  const carregarTarefas = async () => {
    try {
      const response = await axios.get('http://localhost:5000/api/tarefas/minhas', getAuthConfig());
      setTarefas(response.data);
    } catch (error) {
      setMensagem('Erro ao carregar tarefas');
    }
  };

  const atualizarStatusTarefa = async (id, novoStatus) => {
    try {
      await axios.put(`http://localhost:5000/api/tarefas/${id}/status`, { status: novoStatus }, getAuthConfig());
      carregarTarefas();
    } catch (err) {
      setMensagem('Erro ao atualizar status');
    }
  };

  const controlarCronometro = async (id, acao) => {
    try {
      const response = await axios.put(`http://localhost:5000/api/tarefas/${id}/cronometro`, { acao }, getAuthConfig());
      carregarTarefas();
      if (response.data.tempoExcedido) {
        setMensagem('Atenção: O tempo estimado para esta tarefa foi excedido!');
      } else {
        setMensagem(`Cronômetro ${acao}do com sucesso`);
      }
    } catch (err) {
      setMensagem(`Erro ao ${acao} cronômetro`);
    }
  };

  const baixarPDF = async (tarefa) => {
    // Mantendo estrutura original para PDF caso tenha. Backend precisaria devolver isso.
    alert("Função de gerar PDF em progresso");
  };

  const getUrgenciaClass = (urgencia) => {
    if(!urgencia) return '';
    if(urgencia === 'alta') return 'urgencia-alta';
    if(urgencia === 'media') return 'urgencia-media';
    return 'urgencia-baixa';
  };

  const onDragEnd = async (result) => {
    if (!result.destination) return;
    
    const sourceStatus = result.source.droppableId;
    const destStatus = result.destination.droppableId;
    
    if (sourceStatus !== destStatus) {
      const taskId = result.draggableId;
      
      // Atualização otimista da UI
      const updatedTarefas = tarefas.map(t => t._id === taskId ? { ...t, status: destStatus } : t);
      setTarefas(updatedTarefas);
      
      // Persiste no banco
      await atualizarStatusTarefa(taskId, destStatus);
    }
  };

  const colunas = [
    { id: 'pendente', titulo: 'Pendente' },
    { id: 'em_andamento', titulo: 'Em Andamento' },
    { id: 'concluido', titulo: 'Concluído' }
  ];

  const getDragStyle = (isDragging, draggableStyle) => ({
    ...draggableStyle,
    ...(isDragging
      ? {
          zIndex: 5000,
          boxShadow: '0 16px 36px rgba(0, 0, 0, 0.55)',
        }
      : {}),
  });

  return (
    <div className="tarefas-page">
      <Sidebar />

      <div className="tarefas-content">
        <div className="tarefas-container">
        <h2>O seu Painel Kanban de Tarefas</h2>
        {mensagem && <div className={`mensagem ${mensagem.includes('sucesso') ? 'sucesso' : mensagem.includes('Atenção') ? 'alerta' : 'erro'}`}>{mensagem}</div>}
        
        <DragDropContext onDragEnd={onDragEnd}>
          <div className="kanban-board">
            {colunas.map((coluna) => {
              const tarefasDaColuna = tarefas.filter(t => t.status === coluna.id);

              return (
                <Droppable key={coluna.id} droppableId={coluna.id}>
                  {(provided, snapshot) => (
                    <div
                      className="kanban-column"
                      ref={provided.innerRef}
                      {...provided.droppableProps}
                      style={{ backgroundColor: snapshot.isDraggingOver ? 'rgba(255, 255, 255, 0.05)' : '' }}
                    >
                      <h3>{coluna.titulo} <span style={{color: '#b0bec5', fontSize: '0.9rem'}}>({tarefasDaColuna.length})</span></h3>
                      
                      {tarefasDaColuna.map((tarefa, index) => (
                        <Draggable key={tarefa._id} draggableId={tarefa._id} index={index}>
                          {(provided, snapshot) => (
                            (() => {
                              const draggableCard = (
                                <div
                                  className={`tarefa-item ${getUrgenciaClass(tarefa.urgencia)} ${snapshot.isDragging ? 'tarefa-dragging' : ''}`}
                                  ref={provided.innerRef}
                                  {...provided.draggableProps}
                                  {...provided.dragHandleProps}
                                  onClick={() => setTarefaInspecionada(tarefa._id)}
                                  style={getDragStyle(snapshot.isDragging, {
                                    cursor: 'pointer',
                                    ...provided.draggableProps.style,
                                  })}
                                >
                                  <h4>{tarefa.descricao}</h4>
                                  <p><strong>Prazo:</strong> {tarefa.dataEntrega ? new Date(tarefa.dataEntrega).toLocaleDateString() : 'Não definido'}</p>
                                  <p><strong>Urgência:</strong> {tarefa.urgencia ? tarefa.urgencia.toUpperCase() : 'BAIXA'}</p>
                                  
                                  {tarefa.tempoEstimado > 0 && (
                                    <p><strong>Tempo Estimado:</strong> {tarefa.tempoEstimado} min</p>
                                  )}
                                  
                                  {(tarefa.tempoGasto > 0 || tarefa.cronometroAtivo) && (
                                    <p style={{ color: tarefa.tempoExcedido ? '#dc3545' : '#555' }}>
                                      <strong>Tempo Gasto:</strong> {tarefa.tempoGasto || 0} min {tarefa.cronometroAtivo && <span>(⏳ Ativo)</span>}
                                    </p>
                                  )}

                                  <div className="buttons">
                                    {tarefa.status === 'pendente' && (
                                      <button onClick={(e) => { e.stopPropagation(); atualizarStatusTarefa(tarefa._id, 'em_andamento') }} className="iniciar-btn">Iniciar</button>
                                    )}
                                    {tarefa.status === 'em_andamento' && !tarefa.cronometroAtivo && (
                                      <button onClick={(e) => { e.stopPropagation(); controlarCronometro(tarefa._id, 'iniciar'); }} className="iniciar-btn">Play Timer</button>
                                    )}
                                    {tarefa.status === 'em_andamento' && tarefa.cronometroAtivo && (
                                      <button onClick={(e) => { e.stopPropagation(); controlarCronometro(tarefa._id, 'pausar'); }} className="pausar-btn">Pause Timer</button>
                                    )}
                                    {tarefa.status === 'em_andamento' && (
                                      <button onClick={(e) => { e.stopPropagation(); atualizarStatusTarefa(tarefa._id, 'concluido'); }} className="finalizar-btn">Concluir</button>
                                    )}
                                  </div>
                                </div>
                              );

                              return snapshot.isDragging
                                ? createPortal(draggableCard, document.body)
                                : draggableCard;
                            })()
                          )}
                        </Draggable>
                      ))}
                      {provided.placeholder}
                    </div>
                  )}
                </Droppable>
              );
            })}
          </div>
        </DragDropContext>
        {tarefaInspecionada && (
          <TarefaModal 
            tarefaId={tarefaInspecionada} 
            onClose={() => { setTarefaInspecionada(null); carregarTarefas(); }} 
          />
        )}
        </div>
      </div>
    </div>
  );
};

export default TarefasUser;