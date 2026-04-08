const { Server } = require('socket.io');
const Message = require('./models/Message');

const setupSocketInteractions = (server) => {
  const io = new Server(server, {
    cors: {
      origin: '*', // To be restricted to frontend URL in production
      methods: ['GET', 'POST']
    }
  });

  io.on('connection', (socket) => {
    console.log('Novo cliente WebSocket conectado:', socket.id);

    // Quando o usuário abrir o chat da equipe, el entra na 'sala' da equipe
    socket.on('join_equipe', (equipeId) => {
      socket.join(`equipe_${equipeId}`);
      console.log(`Socket ${socket.id} entrou na sala equipe_${equipeId}`);
    });

    // Ouvir mensagens enviadas
    socket.on('send_message', async (data) => {
      try {
        const { equipeId, userId, texto } = data;
        
        // Salva a mensagem no DB
        const message = new Message({
          texto,
          user: userId,
          equipe: equipeId
        });
        await message.save();
        
        // Retorna a mensagem com o nome do usuário associado
        const populatedMessage = await Message.findById(message._id).populate('user', 'nome');

        // Emite a mensagem APENAS para quem estiver na sala dessa equipe
        io.to(`equipe_${equipeId}`).emit('receive_message', populatedMessage);
      } catch(err) {
        console.error('Erro na gravação ou disparo da mensagem (Socket):', err);
      }
    });

    socket.on('disconnect', () => {
      console.log('Cliente WebSocket desconectado:', socket.id);
    });
  });

  return io;
};

module.exports = setupSocketInteractions;
