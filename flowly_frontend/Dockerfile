# Usa imagem oficial do Node.js versão 18 como base para o build
FROM node:18 AS build

# Define o diretório de trabalho dentro do container
WORKDIR /app

ARG REACT_APP_API_URL
ARG REACT_APP_API_PUBLIC_URL
ARG REACT_APP_SOCKET_URL
ARG REACT_APP_ASSISTANT_URL

ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV REACT_APP_API_PUBLIC_URL=$REACT_APP_API_PUBLIC_URL
ENV REACT_APP_SOCKET_URL=$REACT_APP_SOCKET_URL
ENV REACT_APP_ASSISTANT_URL=$REACT_APP_ASSISTANT_URL

# Copia os arquivos package.json e package-lock.json
# Isso permite instalar as dependências antes de copiar o restante do código (cache otimizado)
COPY package*.json ./

# Instala as dependências do projeto React
RUN npm install

# Copia o restante dos arquivos do frontend para o container
COPY . .

# Executa o build de produção do React
# Isso gera os arquivos otimizados na pasta /app/build
RUN npm run build

# Usa uma imagem leve e otimizada do NGINX
FROM nginx:stable-alpine

# Copia o build gerado na etapa anterior para a pasta padrão do NGINX
COPY --from=build /app/build /usr/share/nginx/html

# Expõe a porta 80, que é a porta padrão usada pelo NGINX
EXPOSE 80

# Comando que inicia o NGINX em primeiro plano (modo que mantém o container rodando)
CMD ["nginx", "-g", "daemon off;"]
