# Flowly

Sistema web e mobile de gerenciamento de tarefas, equipes e colaboração em tempo real.
O projeto é uma evolução direta de seu modelo anterior, que pode ser encontrado [aqui](https://github.com/FATEC-Mobile-Group/Flowly)

---

## Sobre o Projeto

O **Flowly** é uma plataforma full stack desenvolvida para gerenciamento de tarefas, equipes e produtividade, oferecendo colaboração em tempo real entre administradores e usuários.

A aplicação é composta por:

* Backend em Node.js + Express
* Frontend Web em React
* Aplicativo Mobile em Flutter
* Banco de dados MongoDB
* Comunicação em tempo real com Socket.IO
* Infraestrutura com Docker, Kubernetes e GitHub Actions
* Módulo auxiliar em Python para mineração de dados e assistente

---

# Arquitetura do Projeto

```text
flowly-2.0/
│
├── flowly_api/          # API REST Node.js + Express
├── flowly_frontend/    # Frontend Web React
├── flowly_mobal/       # Aplicativo Flutter
├── flowly_assistente/  # Assistente e mineração de dados em Python
│
├── docker/             # Containers e infraestrutura
├── kubernetes/         # Manifests Kubernetes
└── .github/            # Pipelines CI/CD
```

---

# Stack Tecnológica

## Backend

* Node.js
* Express
* MongoDB
* Mongoose
* Socket.IO
* JWT
* Argon2
* Multer
* Nodemailer

## Frontend Web

* React
* React Router DOM
* Axios
* Socket.IO Client
* Chart.js
* Recharts
* jsPDF
* Three.js
* @hello-pangea/dnd

## Mobile

* Flutter
* Dart
* Dio
* go_router
* flutter_secure_storage
* socket_io_client

## Infraestrutura

* Docker
* Kubernetes
* GitHub Actions
* Docker Hub

---

# Objetivos

## Objetivo Geral

Desenvolver uma solução web e mobile para:

* Gerenciamento de tarefas
* Organização de equipes
* Acompanhamento de produtividade
* Comunicação em tempo real
* Controle de tempo
* Compartilhamento de arquivos
* Geração de métricas e dashboards

## Problemas Resolvidos

* Centralização de tarefas e equipes
* Comunicação integrada
* Controle de produtividade
* Gestão de prazos e prioridades
* Organização de subtarefas e anexos
* Monitoramento em tempo real

---

# Perfis de Usuário

## Administrador

Pode:

* Criar equipes
* Gerenciar tarefas
* Visualizar dashboards
* Acompanhar métricas
* Gerenciar usuários

## Usuário

Pode:

* Visualizar tarefas atribuídas
* Atualizar status
* Registrar tempo gasto
* Participar de chats
* Adicionar comentários
* Manipular subtarefas
* Realizar upload de anexos

---

# Funcionalidades Principais

## Autenticação

* Cadastro de usuários
* Login com JWT
* Criptografia de senhas com Argon2
* Controle de acesso por roles
* Logout
* Proteção de rotas

## Equipes

* CRUD de equipes
* Associação de membros
* Visualização de participantes
* Código identificador de equipe

## Tarefas

* CRUD completo
* Kanban com drag and drop
* Controle de urgência
* Filtros
* PDF de tarefas
* Modal de detalhes

## Cronômetro

* Iniciar/Pausar
* Controle de tempo gasto
* Tempo excedido
* Atualização em tempo real

## Subtarefas

* Adição
* Marcação/desmarcação
* Organização por abas

## Comentários

* Registro de comentários
* Histórico por tarefa
* Autor e timestamp

## Uploads

* Upload de anexos
* Limite de 10MB
* Controle de MIME types
* Download de arquivos

## Chat em Tempo Real

* Comunicação por equipe
* Histórico persistente
* Socket.IO
* Controle de acesso

## Dashboards

* Métricas gerais
* Ranking de equipes
* Indicadores por status
* Dashboard do usuário

---

# API REST

## Principais Rotas

### Autenticação

```http
POST /api/auth/registrar
POST /api/auth/login
GET  /api/auth/users
```

### Equipes

```http
GET    /api/equipes
POST   /api/equipes
PUT    /api/equipes/:id
DELETE /api/equipes/:id
```

### Tarefas

```http
GET    /api/tarefas
POST   /api/tarefas
PUT    /api/tarefas/:id
DELETE /api/tarefas/:id
PATCH  /api/tarefas/:id/status
```

### Notificações

```http
GET  /api/notificacoes
PATCH /api/notificacoes/:id/read
```

---

# Banco de Dados

## Coleções Principais

| Coleção      | Finalidade               |
| ------------ | ------------------------ |
| User         | Usuários e autenticação  |
| Equipe       | Organização de equipes   |
| Tarefa       | Gerenciamento de tarefas |
| Message      | Chat em tempo real       |
| Comment      | Comentários              |
| Notification | Notificações             |
| ActivityLog  | Histórico de ações       |

---

# Testes

## Estratégia de Testes

### Testes previstos

* Testes funcionais
* Testes E2E
* Testes de integração
* Testes de API
* Testes de regressão
* Testes de usabilidade

## Ferramentas

* Cypress
* Jest
* React Testing Library
* GitHub Actions

## Fluxos já testados

* Login
* Cadastro
* Validação de formulários
* Alternância de senha
* Navegação inicial

---

# Requisitos Não Funcionais

## Segurança

* JWT
* Argon2
* Controle de acesso
* Variáveis de ambiente
* Restrição de uploads
* Configuração CORS

## Usabilidade

* Interface responsiva
* Feedback visual
* Kanban drag and drop
* Modais organizados

## Performance

* WebSocket
* Atualização otimista
* Polling eficiente

---

# Infraestrutura

## Docker

* Containerização da API
* Containerização do Frontend
* Publicação no Docker Hub

## Kubernetes

* Deploy da API
* Deploy do Frontend
* Deploy do MongoDB
* Comunicação entre serviços

## CI/CD

* Build automatizado
* Push de imagens
* GitHub Actions

---

# Execução Local

## Pré-requisitos

* Node.js
* MongoDB
* Docker (opcional)
* Flutter SDK
* Python

## Backend

```bash
cd flowly_api
npm install
cp .env.example .env
npm run dev
```

## Frontend

```bash
cd flowly_frontend
npm install
cp .env.example .env
npm start
```

## Mobile

```bash
cd flowly_mobal
flutter pub get
flutter run
```

## Assistente

```bash
cd flowly_assistente
pip install -r requirements.txt
cp .env.example .env
python main.py --cli

```

---

# Variáveis de Ambiente

### Backend

```env
# API Configuration
PORT_ENV=5000
NODE_ENV=development

# MongoDB
MONGO_URI=mongodb://localhost:27017/Flowly

# GOOGLE CLOUD CONFIG
GCP_PROJECT_ID=id_do_seu_projeto
GCP_BUCKET_NAME=id_do_seu_bucket

# JWT
JWT_SECRET=sua_chave_secreta_segura_aqui
JWT_EXPIRES_IN=7d

# CORS
CORS_ORIGIN=*

# NODEMAILER CONFIG
HOST=smtp.example.com
EMAIL_PORT=587
SECURE=false
AUTH_EMAIL=seu_email@example.com
AUTH_PASSWORD=sua_senha_secreta_aqui
SERVICE=example
```

### Frontend

```env
# API URL
REACT_APP_API_URL=http://localhost:5000/api
```

### Assistente

```env
# Base URL do backend Flowly (repare no /api)
FLOWLY_API_BASE_URL=http://localhost:5000/api

# Token JWT para autenticação com o backend
FLOWLY_API_TOKEN=seu_token_jwt_aqui

# Timeout das requisições HTTP para o backend (segundos)
FLOWLY_API_TIMEOUT_SEC=20

# Threshold de correspondência do parser de comandos (0-100)
# Aumentar: mais permissivo (reconhece comandos com mais variação)
# Diminuir: mais restritivo (reconhece apenas comandos bem similares)
FLOWLY_MATCH_THRESHOLD=78

# Origem CORS permitida (para chamadas do frontend)
# "*" = permite todas as origens
# "https://seu-frontend.com" = permite apenas esse domínio
FLOWLY_CORS_ORIGIN=*

# Modo texto: força entrada via teclado (não usa microfone)
FLOWLY_TEXT_ONLY=False

# Desligar TTS (Text-to-Speech): evita travas do pyttsx3 em alguns ambientes
FLOWLY_TTS_ENABLED=True

# Linguagem para reconhecimento de fala
FLOWLY_LANGUAGE=pt-BR

# Timeouts de audio (segundos)
FLOWLY_LISTEN_TIMEOUT=5
FLOWLY_PHRASE_TIME_LIMIT=10

# Configurações do SpeechRecognition (Google Speech API)
FLOWLY_SR_ENERGY_THRESHOLD=300
FLOWLY_SR_DYNAMIC_ENERGY=True
FLOWLY_SR_PAUSE_THRESHOLD=0.8
FLOWLY_SR_NON_SPEAKING_DURATION=0.5

# TTS Configurações
FLOWLY_TTS_RATE=175
FLOWLY_TTS_VOLUME=1.0

# Habilita logs detalhados (timing das chamadas, stack traces, etc)
FLOWLY_DEBUG=False

# Papel do usuário: se vazio, a assistente tenta descobrir via GET /users/me
# Valores: "admin", "user", ou deixar em branco para auto-detect
FLOWLY_USER_TYPE=
FLOWLY_LANGUAGE=pt-BR
FLOWLY_LISTEN_TIMEOUT=5
FLOWLY_PHRASE_TIME_LIMIT=10

# Ajustes do SpeechRecognition (engine google)
FLOWLY_SR_ENERGY_THRESHOLD=300
FLOWLY_SR_DYNAMIC_ENERGY=True
FLOWLY_SR_PAUSE_THRESHOLD=0.8
FLOWLY_SR_NON_SPEAKING_DURATION=0.5

# Parser
FLOWLY_MATCH_THRESHOLD=78

# TTS
FLOWLY_TTS_RATE=175
FLOWLY_TTS_VOLUME=1.0
```

---

# Funcionalidades Futuras

* Notificações push
* Planos Free/Pro/Enterprise
* Personalização de perfil
* Modo offline
* Analytics avançado
* Busca global
* Internacionalização
* Refresh tokens
* Integrações externas

---

# Mineração de Dados

O módulo de mineração de dados será responsável por:

* Processamento de mensagens do chat
* Filtragem textual
* Agrupamento de mensagens
* Geração de indicadores
* Análise de comunicação

## Tecnologias utilizadas

* Python
* Regex
* Pandas
* Matplotlib
* MongoDB

---

# Qualidade de Software

## Atributos de Qualidade

* Confiabilidade
* Segurança
* Desempenho
* Usabilidade
* Manutenibilidade

## Boas práticas adotadas

* Git Flow simplificado
* Revisão de código
* Commits organizados
* Separação de responsabilidades
* Componentização
* Versionamento com GitHub

---

# Equipe

* Américo Godoy
* Cássia Helena Voltolin
* Gabriel Defende
* Pedro Vasconcellos
* Pedro Lucas dos Santos Hernandes

---

# Instituição

**FATEC Jahu**
Curso de Desenvolvimento de Software Multiplataforma

---

# Referências

- ARGON2. Argon2 Password Hashing Algorithm Documentation. Disponível em: https://argon2-cffi.readthedocs.io/.<br>
- AXIOS. Axios HTTP Client Documentation. Disponível em: https://axios-http.com/docs/intro.<br>
- CHART.JS. Chart.js Documentation. Disponível em: https://www.chartjs.org/docs/latest/. <br>
- CYPRESS. Cypress Documentation. Disponível em: https://docs.cypress.io/. <br>
- DART. Dart Language Documentation. Disponível em: https://dart.dev/guides. <br>
- DOCKER. Docker Documentation. Disponível em: https://docs.docker.com/.<br>
- EXPRESS. Express.js Documentation. Disponível em: https://expressjs.com/.<br>
- FLUTTER. Flutter Documentation. Disponível em: https://docs.flutter.dev/. <br>
- GITHUB. GitHub Actions Documentation. Disponível em: https://docs.github.com/actions. <br>
- GOOGLE. Google Cloud Storage Documentation. Disponível em: https://cloud.google.com/storage/docs. <br>
- GOOGLE FONTS. Google Fonts Documentation. Disponível em: https://fonts.google.com/. <br>
- JEST. Jest Documentation. Disponível em: https://jestjs.io/docs/getting-started.<br>
- JSON WEB TOKEN. JWT Introduction and Documentation. Disponível em: https://jwt.io/introduction. <br>
- KUBERNETES. Kubernetes Documentation. Disponível em: https://kubernetes.io/docs/home/. <br>
- MATPLOTLIB DEVELOPMENT TEAM. Matplotlib Documentation. Disponível em: https://matplotlib.org/stable/index.html. <br>
- MONGODB. MongoDB Documentation. Disponível em: https://www.mongodb.com/docs/.<br>
- MONGOOSE. Mongoose ODM Documentation. Disponível em: https://mongoosejs.com/docs/. <br>
- MULTER. Multer Documentation. Disponível em: https://github.com/expressjs/multer. <br>
- NODEMAILER. Nodemailer Documentation. Disponível em: https://nodemailer.com/about/.<br>
- NODE.JS. Node.js Documentation. Disponível em: https://nodejs.org/en/docs. <br>
- PANDAS DEVELOPMENT TEAM. Pandas Documentation. Disponível em: https://pandas.pydata.org/docs/. <br>
- PYTHON SOFTWARE FOUNDATION. Python Documentation. Disponível em: https://docs.python.org/3/.<br>
- REACT. React Documentation. Disponível em: https://react.dev/.<br>
- REACT ROUTER. React Router Documentation. Disponível em: https://reactrouter.com/en/main. <br>
- RECHARTS. Recharts Documentation. Disponível em: https://recharts.org/en-US/. <br>
- SOCKET.IO. Socket.IO Documentation. Disponível em: https://socket.io/docs/v4/. <br>
- TESTING LIBRARY. React Testing Library Documentation. Disponível em: https://testing-library.com/docs/react-testing-library/intro/.<br>
- THREE.JS. Three.js Documentation. Disponível em: https://threejs.org/docs/.<br>
- FATEC-MOBILE-GROUP. flowly-2.0. Repositório GitHub. Disponível em: https://github.com/FATEC-Mobile-Group/flowly-2.0.<br>
- ISO25000. ISO/IEC 25010 – Systems and software Quality Requirements and Evaluation (SQuaRE). Disponível em: https://iso25000.com/index.php/en/iso-25000-standards/iso-25010.<br>

---

# 📄 Licença

Este projeto foi desenvolvido para fins acadêmicos no Projeto Integrador da FATEC Jahu.
