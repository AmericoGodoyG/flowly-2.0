import React, { useState, useEffect, useRef } from 'react';
import createSocketConnection from '../../config/socketClient';
import apiClient from '../../config/apiClient';
import { authUtils } from '../../config/authUtils';
import { API_ENDPOINTS } from '../../config/config';
import '../../styles/components/ChatPanel.css';

const ChatPanel = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [equipes, setEquipes] = useState([]);
  const [selectedEquipe, setSelectedEquipe] = useState(null);
  const [messages, setMessages] = useState([]);
  const [novaMensagem, setNovaMensagem] = useState('');
  const [socket, setSocket] = useState(null);
  
  const messagesEndRef = useRef(null);
  const userId = authUtils.getUserId();

  // Carregar equipes
  useEffect(() => {
    const fetchEquipes = async () => {
      try {
        const res = await apiClient.get(API_ENDPOINTS.MINHAS_EQUIPES);
        setEquipes(res.data);
        if (res.data.length > 0) {
          setSelectedEquipe(res.data[0]._id);
        }
      } catch (err) {
        console.error('Erro ao carregar equipes para o chat', err);
      }
    };
    fetchEquipes();
  }, [userId]);

  // Conectar WebSockets quando a equipe selecionada mudar
  useEffect(() => {
    if (!selectedEquipe) return;

    // Conectar ao socket do Backend
    const newSocket = createSocketConnection();
    setSocket(newSocket);

    // Entrar na sala da Equipe
    newSocket.emit('join_equipe', selectedEquipe);

    // Carregar histórico via HTTP
    const fetchHistory = async () => {
      try {
        const res = await apiClient.get(`/equipes/${selectedEquipe}/messages`);
        setMessages(res.data);
      } catch (error) {
        console.error('Erro ao buscar histórico de mensagens');
      }
    };
    fetchHistory();

    // Atender mensagens do WebSocket
    newSocket.on('receive_message', (msg) => {
      setMessages((prev) => [...prev, msg]);
    });

    return () => {
      newSocket.disconnect();
    };
  }, [selectedEquipe]);

  // Sempre rolar para a última mensagem
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages, isOpen]);

  const handleSendMessage = (e) => {
    e.preventDefault();
    if (!novaMensagem.trim() || !socket || !selectedEquipe) return;

    socket.emit('send_message', {
      equipeId: selectedEquipe,
      userId: userId,
      texto: novaMensagem
    });

    setNovaMensagem('');
  };

  if (equipes.length === 0) return null;

  return (
    <div className={`chat-panel-container ${isOpen ? 'open' : ''}`}>
      {!isOpen && (
        <button className="chat-toggle-btn" onClick={() => setIsOpen(true)}>
          💬 Chat da Equipe
        </button>
      )}

      {isOpen && (
        <div className="chat-window">
          <div className="chat-header">
            <select 
              value={selectedEquipe} 
              onChange={(e) => setSelectedEquipe(e.target.value)}
              className="chat-equipe-select"
            >
              {equipes.map(eq => (
                <option key={eq._id} value={eq._id}>{eq.nome}</option>
              ))}
            </select>
            <button className="close-btn" onClick={() => setIsOpen(false)}>✕</button>
          </div>

          <div className="chat-messages">
            {messages.map((msg, index) => {
              const isMine = msg.user && msg.user._id === userId;
              return (
                <div key={index} className={`message-wrapper ${isMine ? 'mine' : 'theirs'}`}>
                  {!isMine && <span className="message-author">{msg.user ? msg.user.nome : 'Usuário'}</span>}
                  <div className="message-bubble">
                    {msg.texto}
                  </div>
                </div>
              );
            })}
            <div ref={messagesEndRef} />
          </div>

          <form className="chat-input-form" onSubmit={handleSendMessage}>
            <input 
              type="text" 
              placeholder="Digite sua mensagem..." 
              value={novaMensagem}
              onChange={(e) => setNovaMensagem(e.target.value)}
            />
            <button type="submit">Enviar</button>
          </form>
        </div>
      )}
    </div>
  );
};

export default ChatPanel;
