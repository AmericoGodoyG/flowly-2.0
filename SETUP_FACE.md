# Flowly 2.0 — Setup do Reconhecimento Facial

Guia para rodar localmente (desenvolvimento e teste no PC do colega) e orientações para deploy na nuvem.

---

## Pré-requisitos

| Ferramenta | Versão sugerida |
|------------|-----------------|
| Node.js | 18+ |
| MongoDB | local ou Atlas |
| Python | 3.10 a 3.13 (testado em 3.13) |
| npm | incluído com Node |
| Flutter SDK | apenas se for testar mobile |
| Git | opcional |

**Observação Windows:** na primeira execução do DeepFace, o pacote `tf-keras` é instalado via `requirements.txt` e o modelo `vgg_face_weights.h5` (~550 MB) é baixado automaticamente (requer internet). A instalação e a **primeira captura facial** podem levar vários minutos.

**Observação cadastro/login:** a verificação por **e-mail** do Flowly usa SMTP no `flowly_api/.env`. Com valores de exemplo (`smtp.example.com`), o e-mail **não chega** — o usuário fica `verificado: false` e não loga. Para testes locais, configure SMTP real ou marque o usuário como verificado no MongoDB (veja seção abaixo).

---

## Estrutura dos serviços

| Serviço | Pasta | Porta | Comando |
|---------|-------|-------|---------|
| API Node | `flowly_api` | **5000** | `npm run dev` |
| Face Python | `flowly_iot_face` | **5001** | `python main.py` |
| Frontend Web | `flowly_frontend` | **3000** | `npm start` |
| Mobile | `flowly_mobal` | — | `flutter run` |

**Ordem recomendada:** MongoDB → Python (5001) → API (5000) → Frontend/Mobile.

---

## Passo 1 — MongoDB

Certifique-se de que o MongoDB está acessível com a URI do `.env` da API:

```env
MONGO_URI=mongodb://localhost:27017/Flowly
```

---

## Passo 2 — Microserviço facial (Python)

```bash
cd flowly_iot_face
python -m venv .venv
```

**Windows (PowerShell):**

```powershell
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
python main.py
```

**Linux / macOS:**

```bash
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python main.py
```

Verifique:

```bash
curl http://localhost:5001/health
```

Resposta esperada: `"status": "ok"`.

---

## Passo 3 — API Node

```bash
cd flowly_api
npm install
```

Copie e edite o `.env`:

```bash
copy .env.example .env
```

Adicione/confirme:

```env
PORT_ENV=5000
MONGO_URI=mongodb://localhost:27017/Flowly
JWT_SECRET=sua_chave_secreta_segura_aqui

FACE_SERVICE_URL=http://localhost:5001
FACE_MATCH_THRESHOLD=0.4
FACE_SESSION_EXPIRES_IN=5m
FACE_ENROLL_SESSION_EXPIRES_IN=10m
```

Inicie:

```bash
npm run dev
```

Teste integração:

```bash
curl http://localhost:5000/api/face/health
```

Deve retornar `"api": "ok"` e dados do serviço Python.

---

## Passo 4 — Frontend Web

```bash
cd flowly_frontend
npm install
```

`.env`:

```env
REACT_APP_API_URL=http://localhost:5000/api
```

```bash
npm start
```

Acesse `http://localhost:3000`, faça login com usuário **colaborador** (`tipo: user`), permita acesso à câmera no navegador.

---

## Passo 5 — App Mobile (opcional)

```bash
cd flowly_mobal
flutter pub get
```

Arquivo `.env` na raiz do app:

```env
FLOWLY_API_URL=http://10.0.2.2:5000
```

- **Emulador Android:** `10.0.2.2` aponta para `localhost` do PC.
- **Dispositivo físico na mesma rede:** use o IP da máquina, ex.: `http://192.168.1.50:5000`.

```bash
flutter run
```

Permita permissão de câmera no dispositivo.

---

## Teste rápido do fluxo

1. Crie ou use um usuário **verificado** (`verificado: true`) do tipo **user**.
2. Faça login com e-mail + senha.
3. Na **primeira vez**, deve aparecer convite de cadastro facial (opcional).
4. Cadastre o rosto ou pule.
5. Faça logout e login novamente:
   - Se cadastrou → pede verificação facial.
   - Se pulou → entra direto.
6. Cadastro tardio: **Perfil → Verificação facial** (web ou mobile).

### Usuário verificado sem e-mail (apenas desenvolvimento local)

Se o SMTP não estiver configurado, após criar a conta rode na pasta `flowly_api`:

```bash
node -e "require('dotenv').config(); const mongoose=require('mongoose'); const User=require('./models/User'); mongoose.connect(process.env.MONGO_URI).then(async()=>{ await User.updateOne({email:'SEU_EMAIL@exemplo.com'},{verificado:true}); console.log('ok'); process.exit(0);})"
```

Substitua `SEU_EMAIL@exemplo.com` pelo e-mail cadastrado.

---

## Obter o código (GitHub)

Este módulo está publicado em:

**https://github.com/gabrieldefende/Reconhecimento-Facial**

### Para integrar no Flowly 2.0

1. Clone o Flowly principal do grupo:

```bash
git clone https://github.com/FATEC-Mobile-Group/flowly-2.0.git
cd flowly-2.0
```

2. Clone este repositório e **copie** os arquivos para dentro do `flowly-2.0` (mesmos caminhos de pasta):

```bash
git clone https://github.com/gabrieldefende/Reconhecimento-Facial.git
```

Consulte **[INTEGRACAO.md](./INTEGRACAO.md)** para a lista completa de arquivos novos e alterados.

3. Instale dependências e configure `.env` (passos abaixo).

### O que **não** vem no Git

- `node_modules/` — rode `npm install` em `flowly_api` e `flowly_frontend`
- `flowly_iot_face/.venv/` — rode `pip install -r requirements.txt`
- Arquivos `.env` — copie de `.env.example`
- Modelo `vgg_face_weights.h5` (~550 MB) — baixado na 1ª execução ou manualmente (seção Solução de problemas)

### Rodar após integrar (3 terminais)

```text
Terminal 1 → flowly_iot_face  → python main.py
Terminal 2 → flowly_api       → npm run dev
Terminal 3 → flowly_frontend  → npm start
```

**Dica Windows:** se `pip install` falhar, instale [Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/) e use Python 3.10+.

---

## Deploy na nuvem (sem quebrar o resto do projeto)

A arquitetura foi feita para trocar **apenas a URL** do serviço facial.

### Cenário A — API na cloud, face local (dev)

```env
# flowly_api/.env na cloud — NÃO recomendado para produção
FACE_SERVICE_URL=http://SEU_IP_PUBLICO:5001
```

Requer port forwarding / firewall aberto (apenas para testes).

### Cenário B — Face na cloud (recomendado para grupo)

1. Hospede `flowly_iot_face` em um serviço que suporte Python + dependências pesadas:
   - **Google Cloud Run** (mesma região da API da equipe: `southamerica-east1`) — **recomendado**
   - Railway, Render, VM Linux (AWS/Azure/GCP)
2. Use o **`Dockerfile`** incluído em `flowly_iot_face/` ou siga **[DEPLOY_FACE_NUVEM.md](./DEPLOY_FACE_NUVEM.md)** (passo a passo para o Flowly FATEC).
3. Exponha HTTPS, ex.: `https://flowly-face-iot-646126851973.southamerica-east1.run.app`.
4. Atualize **somente** as variáveis de ambiente da API Node no Cloud Run:

```env
FACE_SERVICE_URL=https://flowly-face-iot-646126851973.southamerica-east1.run.app
```

5. Frontend e mobile **não precisam** da URL do Python — falam só com a API Node.

### Checklist cloud do serviço Python

- [ ] Python 3.10+ no servidor
- [ ] `pip install -r requirements.txt`
- [ ] Variáveis `HOST=0.0.0.0`, `PORT` definida pelo provedor
- [ ] Memória suficiente (DeepFace/TensorFlow: **≥ 2 GB RAM** recomendado)
- [ ] Primeiro request pode demorar (download/cache de modelos)
- [ ] HTTPS habilitado
- [ ] `FACE_SERVICE_URL` atualizada na API

### O que **não** muda no deploy

- Rotas de tarefas, equipes, chat, notificações.
- Login admin.
- Usuários sem face cadastrada.
- Frontend/mobile (desde que `REACT_APP_API_URL` / `FLOWLY_API_URL` apontem para a API correta).

---

## Solução de problemas

| Problema | Possível causa | Ação |
|----------|----------------|------|
| `Serviço facial indisponível` | Python não rodando | Inicie `flowly_iot_face` na 5001 |
| `Nenhum rosto detectado` | Iluminação / rosto fora do quadro | Melhore luz, centralize o rosto |
| `Rosto não reconhecido` | Limiar rigoroso ou aparência diferente | Ajuste `FACE_MATCH_THRESHOLD` |
| Câmera bloqueada no browser | Permissão negada | Liberar câmera nas configurações do site |
| Mobile não conecta na API | URL errada | Use IP da máquina ou `10.0.2.2` no emulador |
| `pip install` lento/falha | TensorFlow + DeepFace pesados | Use venv limpo, Python 3.10+, boa internet |
| Erro `tf-keras` / `build_model` | Dependência ou serviço desatualizado | `pip install tf-keras` e **reinicie** `python main.py` |
| Erro ao baixar `vgg_face_weights.h5` | Download interrompido na 1ª vez | Baixe manualmente para `%USERPROFILE%\.deepface\weights\` (veja abaixo) |
| Cadastro facial demora muito | 1ª execução carrega modelo (~550 MB) | Aguarde até 1–2 min na primeira captura |

### Download manual do modelo VGG-Face (se necessário)

```powershell
mkdir $env:USERPROFILE\.deepface\weights -Force
curl.exe -L -o $env:USERPROFILE\.deepface\weights\vgg_face_weights.h5 `
  "https://github.com/serengil/deepface_models/releases/download/v1.0/vgg_face_weights.h5"
```

Depois reinicie o serviço: `python main.py` em `flowly_iot_face/`.

---

## Arquivos de referência

- Documentação técnica completa: [`FACE_RECONHECIMENTO.md`](./FACE_RECONHECIMENTO.md)
- Env exemplo API: `flowly_api/.env.example`
- Env exemplo Python: `flowly_iot_face/.env.example`

---

## Contato interno (grupo)

Este módulo foi projetado para PR isolado no Flowly 2.0. Repositório da feature:

- https://github.com/gabrieldefende/Reconhecimento-Facial

Ao integrar no repositório do grupo, inclua:

1. Pasta `flowly_iot_face/`
2. Arquivos listados em `INTEGRACAO.md`
3. `SETUP_FACE.md`, `FACE_RECONHECIMENTO.md` e este guia
