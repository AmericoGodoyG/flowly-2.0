# Integração — Reconhecimento Facial no Flowly 2.0 (equipe FATEC)

Pasta **`flowly-2.0-integracao-face/`** = clone do [flowly-2.0 da equipe](https://github.com/FATEC-Mobile-Group/flowly-2.0) **já mesclado** com o módulo de [Reconhecimento-Facial](https://github.com/gabrieldefende/Reconhecimento-Facial), incluindo deploy na nuvem (Cloud Run).

> O repositório da equipe **não foi alterado**. Use esta pasta como base para criar sua branch e abrir o PR.

---

## Como abrir o PR (passo a passo)

1. Clone o repositório da equipe:

```bash
git clone https://github.com/FATEC-Mobile-Group/flowly-2.0.git
cd flowly-2.0
git checkout -b feature/reconhecimento-facial
```

2. Copie **todo o conteúdo** de `flowly-2.0-integracao-face/` para dentro do clone (substituindo/adicionando arquivos).

   **Windows (PowerShell)** — ajuste os caminhos:

```powershell
robocopy "C:\Users\henri\Desktop\flowly-2.0-main\flowly-2.0-integracao-face" "C:\caminho\flowly-2.0" /E /XD .git
```

3. Revise o diff (`git status` / `git diff`) — devem aparecer apenas arquivos relacionados à face + docs.

4. Commit, push e abra o PR para `main` do grupo.

5. Após merge, siga **[DEPLOY_FACE_NUVEM.md](./DEPLOY_FACE_NUVEM.md)** para subir o Python no Cloud Run e configurar `FACE_SERVICE_URL` na API.

---

## O que foi mesclado (vs baseline da equipe)

### Arquivos novos

| Área | Arquivos |
|------|----------|
| **API** | `FaceProfile.js`, `faceRoutes.js`, `faceController.js`, `faceService.js`, `faceAuth.js` |
| **Python** | Pasta `flowly_iot_face/` (+ `Dockerfile`, `.dockerignore`) |
| **Web** | `src/components/face/*`, `FaceCapture.css`, `FaceAuthStep.css` |
| **Mobile** | `face_service.dart`, `face_auth_screen.dart`, `face_profile_screen.dart` |
| **Docs** | `FACE_RECONHECIMENTO.md`, `SETUP_FACE.md`, `DEPLOY_FACE_NUVEM.md`, este arquivo |

### Arquivos alterados (merge cirúrgico)

| Arquivo | Mudança |
|---------|---------|
| `flowly_api/models/User.js` | +`faceEnrollmentOffered`, `faceEnrollmentSkipped` |
| `flowly_api/controllers/authController.js` | Login condicional (admin direto; user com face) |
| `flowly_api/controllers/userController.js` | `/users/me` retorna campos face (**GCS upload preservado**) |
| `flowly_api/config/config.js` | Bloco `face.*` |
| `flowly_api/app.js` | Rota `/api/face` |
| `flowly_api/.env.example` | Variáveis `FACE_*` |
| `flowly_frontend/src/config/config.js` | Endpoints `FACE_*` (URL Cloud Run da equipe mantida) |
| `flowly_frontend/src/config/routes.js` | Rota `/perfil` para **user** |
| `flowly_frontend/src/pages/auth/AuthPage.jsx` | Fluxo pós-login facial |
| `flowly_frontend/src/pages/user/PerfilUser.jsx` | Cadastro facial no perfil |
| `flowly_mobal/...` | `auth_service`, `auth_result`, `login_screen`, `profile_screen`, `flowly_router` |

### O que **não** muda

- Tarefas, equipes, chat, notificações, assistente de voz
- Login **admin** (sem verificação facial)
- Upload de foto de perfil via Google Cloud Storage
- URLs de produção do frontend (`flowly-api-backend-...run.app`)

---

## Variáveis de ambiente

### Local (`flowly_api/.env`)

```env
FACE_SERVICE_URL=http://localhost:5001
FACE_MATCH_THRESHOLD=0.4
FACE_SESSION_EXPIRES_IN=5m
FACE_ENROLL_SESSION_EXPIRES_IN=10m
```

### Produção (Cloud Run da API)

```env
FACE_SERVICE_URL=https://flowly-face-iot-SEU_PROJETO.southamerica-east1.run.app
```

Detalhes em **[DEPLOY_FACE_NUVEM.md](./DEPLOY_FACE_NUVEM.md)**.

---

## Teste após integrar

1. Local: subir Python (5001) + API (5000) + frontend — ver **SETUP_FACE.md**
2. `GET /api/face/health` → `"api": "ok"`
3. Login **user** verificado → convite ou verificação facial
4. Login **admin** → JWT direto, sem face

---

## Ordem de deploy recomendada (equipe)

1. Merge do PR (código Node + web + mobile)
2. Deploy `flowly_iot_face` no Cloud Run
3. Atualizar env vars da API com `FACE_SERVICE_URL`
4. Testar `/api/face/health` e fluxo de login user
