/**
 * Cliente Socket.io centralizado para toda a aplicação
 * Garante que a conexão socket use a URL correta do ambiente
 */

import io from 'socket.io-client';
import { authUtils } from './authUtils';

// Obtém a URL do socket das variáveis de ambiente
const SOCKET_URL = process.env.REACT_APP_SOCKET_URL || 'http://localhost:5000';

/**
 * Cria uma nova conexão socket com autenticação
 */
export const createSocketConnection = () => {
  const token = authUtils.getToken();
  
  const socket = io(SOCKET_URL, {
    auth: {
      token: token,
    },
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 5000,
    reconnectionAttempts: 5,
  });

  socket.on('connect', () => {
    console.log('Socket conectado:', socket.id);
  });

  socket.on('disconnect', () => {
    console.log('Socket desconectado');
  });

  socket.on('connect_error', (error) => {
    console.error('Erro ao conectar socket:', error);
  });

  return socket;
};

/**
 * Obtém a URL do socket
 */
export const getSocketUrl = () => SOCKET_URL;

export default createSocketConnection;
