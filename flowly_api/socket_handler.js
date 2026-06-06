const { Server } = require('socket.io');
const Message = require('./models/Message');
const Equipe = require('./models/Equipe');
const User = require('./models/User');
const { notifyUsers } = require('./utils/notificationService');
const { setIo, getIo } = require('./utils/socketInstance');
const { getSignedUrl } = require('./services/storage');

const setupSocketInteractions = (server) => {
  const io = new Server(server, {
    cors: {
      origin: '*', // To be restricted to frontend URL in production
      methods: ['GET', 'POST']
    }
  });

  setIo(io);

  io.on('connection', (socket) => {
    console.log('Novo cliente WebSocket conectado:', socket.id);

    socket.on('join_user', (userId) => {
      socket.join(`user_${userId}`);
      console.log(`Socket ${socket.id} entrou na sala user_${userId}`);
    });

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
        
        // Retorna a mensagem com os dados visuais do usuario associado
        const populatedMessage = await Message.findById(message._id).populate('user', 'nome fotoPerfil');
        const messageToEmit = populatedMessage.toObject();
        if (messageToEmit.user) {
          messageToEmit.user.fotoPerfil = await getSignedUrl(messageToEmit.user.fotoPerfil);
        }

        const equipe = await Equipe.findById(equipeId).populate('membros', 'nome email');
        const sender = await User.findById(userId).select('nome tipo');

        if (equipe) {
          const recipientIds = new Set();

          equipe.membros.forEach((membro) => {
            if (String(membro._id) !== String(userId)) {
              recipientIds.add(String(membro._id));
            }
          });

          if (equipe.createdBy && String(equipe.createdBy) !== String(userId)) {
            const adminCreator = await User.findById(equipe.createdBy).select('tipo');
            if (adminCreator && adminCreator.tipo === 'admin') {
              recipientIds.add(String(equipe.createdBy));
            }
          }

          await notifyUsers({
            userIds: [...recipientIds],
            texto: `${sender?.nome || 'Um usuário'} enviou uma mensagem no chat da equipe ${equipe.nome}`,
            tipo: 'chat',
            origemId: message._id,
            metadata: { equipeId, messageId: message._id },
          });
        }

        // Emite a mensagem APENAS para quem estiver na sala dessa equipe
        io.to(`equipe_${equipeId}`).emit('receive_message', messageToEmit);
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

setupSocketInteractions.getIo = () => getIo();

module.exports = setupSocketInteractions;
