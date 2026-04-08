# Flowly

Sistema completo de gerenciamento de tarefas e equipes, projetado para facilitar a colaboração, acompanhamento de progresso e visualização de dados. O projeto é divido em um **Backend (API)** construído com Node.js e MongoDB, e um **Frontend** interativo construído com React.

## 🛠 Arquitetura e Tecnologias

O repositório é composto por dois módulos principais:

### [1] `flowly_api` (Backend)
API responsável pela regra de negócios, comunicação com banco de dados e gerenciamento em tempo real de eventos.
- **Node.js** + **Express**: Servidor web ágil e robusto.
- **MongoDB** + **Mongoose**: Banco de dados NoSQL e modelagem de objetos.
- **Socket.io**: Comunicação em tempo real para atualizações síncronas.
- **JWT (JSON Web Token)**: Autenticação e segurança das rotas.
- **Argon2**: Hashing criptográfico seguro de senhas.
- **Multer**: Processamento e upload de arquivos.

### [2] `flowly_frontend` (Frontend)
Interface de usuário moderna para administração e visualização dinâmicas de tarefas.
- **React**: Biblioteca principal para construção de UI.
- **React Router DOM**: Navegação de páginas (SPA).
- **Axios**: Cliente HTTP para requisições na API.
- **Socket.io Client**: Escuta de eventos em tempo real provenientes da API.
- **Chart.js** & **Recharts**: Gráficos analíticos e dashboards.
- **@hello-pangea/dnd**: Sistema de *Drag and Drop* para gestão de tarefas no estilo Kanban.
- **Three.js**: Elementos visuais em 3D.
- **jsPDF**: Geração de faturas e relatórios em PDF.

---

## ⚙️ Pré-requisitos
Antes de prosseguir, certifique-se de ter os seguintes itens instalados no seu ambiente de desenvolvimento:
- [Node.js](https://nodejs.org/) (Versão 16 ou superior)
- [MongoDB](https://www.mongodb.com/) rodando localmente (porta 27017) ou uma String de Conexão remota (ex: MongoDB Atlas).

---

## 🚀 Como Rodar o Projeto Localmente

### Passo 1: Iniciar o Banco de Dados
Certifique-se de iniciar o serviço do seu banco MongoDB. Caso prefira utilizar Docker, você pode rodar:
```bash
docker run -d -p 27017:27017 --name mongo mongo:latest
```

### Passo 2: Configurar e Rodar o Backend API
Abra um terminal e acesse o diretório da API:
```bash
cd flowly_api
```

Instale todas as dependências:
```bash
npm install
```

Configure as Variáveis de Ambiente. Copie as variáveis de exemplo para ativá-las:
```bash
cp .env.example .env
```
> **Nota:** Certifique-se de preencher a variável `JWT_SECRET` com uma string forte dentro do arquivo `.env` criado. A variável `MONGO_URI` já vem configurada para uma instância local por padrão.

Inicie o servidor (em ambiente de desenvolvimento):
```bash
npm run dev
```
O servidor deverá constar como iniciado e rodando na porta `http://localhost:5000`.

### Passo 3: Configurar e Rodar o Frontend
Mantenha o terminal da API em execução. Abra um **novo terminal** e acesse a pasta raiz correspondente do React:
```bash
cd flowly_frontend
```

Instale as dependências:
```bash
npm install
```

Configure as Variáveis de Ambiente do painel:
```bash
cp .env.example .env
```
> **Nota:** Por padrão a conexão buscará pela API operando em `http://localhost:5000/api`. Se alterou a porta da API, ajuste também a variável `REACT_APP_API_URL`.

Inicie a aplicação de forma interativa:
```bash
npm start
```
Uma janela do navegador será aberta automaticamente carregando o portal Web do Flowly em `http://localhost:3000`.

---

## 🐋 Rodando com Docker (Opcional)
Se houver preferência por conteinerização, ambos os diretórios (`flowly_api` e `flowly_frontend`) já contém um arquivo `Dockerfile` pré-configurado e pronto para ter sua imagem construída:
```bash
docker build -t flowly-api ./flowly_api
docker build -t flowly-frontend ./flowly_frontend
```
*(Você também pode utilizar o diretório `k8s` localizado dentro de ambos os projetos para fazer um deploy em Kubernetes, se preferir uma arquitetura altamente escalável).*
